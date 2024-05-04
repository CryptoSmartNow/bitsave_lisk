import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { Constants } from "../utils/constants";
import ERC20ABI = require('./abis/Dai.json');
import { childContractGenerate } from "../utils/generator";

describe("Bitsave", function() {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deployBitsave() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    // Contracts are deployed using the first signer/account by default
    const [owner, user_one, optedUser] = await hre.ethers.getSigners();

    const Bitsave = await hre.ethers.getContractFactory("Bitsave");
    const bitsave = await Bitsave.deploy(
      Constants.stableCoin,
      Constants.csToken,
      { value: Constants.initialBalance }
    );

    // Create an opted user for tests that need one
    await bitsave.connect(optedUser).joinBitsave({ value: Constants.joinFee });

    // Connect back to owner
    bitsave.connect(owner);

    const ChildBitsave = await hre.ethers.getContractFactory("ChildBitsave")

    return { Bitsave, ChildBitsave, bitsave, owner, user_one, optedUser };
  }

  describe("Deployment", function() {
    it("Should set the required stable coin", async function() {
      const { bitsave } = await loadFixture(deployBitsave)

      expect(await bitsave.stableCoin()).to.equal(ethers.getAddress(Constants.stableCoin));
    });
    it("Should set the csToken and initial balance for pool", async function() {
      const { bitsave } = await loadFixture(deployBitsave);

      expect(await bitsave.csToken()).to.equal(ethers.getAddress(Constants.csToken));
    });
    it("Should set address of master", async function() {
      const { bitsave, owner } = await loadFixture(deployBitsave);

      expect(await bitsave.masterAddress()).to.equal(await owner.getAddress())
    });
    it("Should set the user count to one since we have a default user", async function() {
      const { bitsave } = await loadFixture(deployBitsave);

      expect(await bitsave.userCount()).to.equal(1);
    });

    // it("Should receive and store the funds to lock", async function () {
    //   const { lock, lockedAmount } = await loadFixture(
    //     deployOneYearLockFixture
    //   );
    //
    //   expect(await hre.ethers.provider.getBalance(lock.target)).to.equal(
    //     lockedAmount
    //   );
    // });
    //
    // it("Should fail if the unlockTime is not in the future", async function () {
    //   // We don't use the fixture here because we want a different deployment
    //   const latestTime = await time.latest();
    //   const Lock = await hre.ethers.getContractFactory("Lock");
    //   await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //     "Unlock time should be in the future"
    //   );
    // });
  });

  describe("JoinBitsave", function() {
    describe("Actions", function() {
      it("Should return a valid address for user's child contract", async function() {
        const { bitsave } = await loadFixture(deployBitsave);
        await bitsave.joinBitsave({ value: Constants.joinFee });
        expect(await bitsave.getUserChildContractAddress()).to.be.properAddress;
      });

      it("Should revert with AmountNotEnough if join fee is lower than limit", async function() {
        const { Bitsave, bitsave } = await loadFixture(deployBitsave);
        await expect(bitsave.joinBitsave({ value: 2 })).to.be.revertedWithCustomError(
          Bitsave,
          "AmountNotEnough")
      });

      it("Should return owner address from child contract", async function() {
        const { bitsave, ChildBitsave, owner } = await loadFixture(deployBitsave);
        await bitsave.joinBitsave({ value: Constants.joinFee });
        const childAddress = await bitsave.getUserChildContractAddress();

        const CC = ChildBitsave.attach(childAddress);
        // @ts-ignore
        expect(await CC.ownerAddress()).to.equal(await owner.getAddress())
      })
    })

    describe("Events", function() {
      it("Should emit event on join bitsave successfully", async function() {
        const { bitsave, owner } = await loadFixture(deployBitsave);
        await expect(bitsave.joinBitsave({ value: Constants.joinFee }))
          .to.emit(bitsave, "JoinedBitsave")
          .withArgs(await owner.getAddress())
      })
    })
  })

  describe("Create Savings", function() {

    const savingData = {
      name: "Hospital Fee",
      maturityTime: Math.round(Date.now() / 1000 + 3000).toString(),
      penaltyPercentage: ethers.toBigInt(1),
      amountEth: ethers.parseEther("0.1"),
    }

    describe("Actions", function() {
      it("Should revert if user is not a member", async function() {
        const { bitsave } = await loadFixture(deployBitsave)
        await expect(bitsave.createSaving(
          savingData.name,
          savingData.maturityTime,
          savingData.penaltyPercentage,
          false,
          ethers.ZeroAddress,
          ethers.parseEther("0.5"),
          { value: ethers.parseEther("0.5") }
        )).to.be.revertedWithCustomError(bitsave, "UserNotRegistered")
      });

      it("Should create a saving with all appropriate data", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);
        const optedUserBalanceBefore = await ethers.provider.getBalance(optedUser);
        console.log(optedUserBalanceBefore)
        await (
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              ethers.parseEther("0.1"),
              { value: Constants.savingFee }
            )
        );
        const userChildContractAddress = await bitsave
          .connect(optedUser).getUserChildContractAddress();
        console.log("uaddr", userChildContractAddress)
        const { userChildContract } = await childContractGenerate(userChildContractAddress);

        // @ts-ignore
        const hospitalSaving = await userChildContract
          .connect(optedUser)
          .getSaving(savingData.name);

        expect(hospitalSaving.isValid).to.be.true;
        expect(hospitalSaving.amount).to.not.equal(0);
        expect(hospitalSaving.tokenId).to.equal(ethers.ZeroAddress);
        expect(hospitalSaving.maturityTime).to.equal(savingData.maturityTime)

      });

      it("Should revert if saving fee is not sent", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);
        await expect(
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              ethers.parseEther("0.1"),
            )
        ).to
          .be.revertedWithCustomError(bitsave, "NotEnoughToPayGasFee")
      });

      it("Should revert if time is invalid", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);
        await expect(
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              Math.round(Date.now() / 1000 - 3000).toString(),
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              savingData.amountEth,
              { value: Constants.savingFee }
            )
        ).to
          .be.revertedWithCustomError(bitsave, "InvalidTime")
      });

      it("Should take note of saving mode and withdraw appropriately");
      it("Should revert if saving name has been used before", async function() {
        const { bitsave, optedUser, ChildBitsave } = await loadFixture(deployBitsave);
        await (
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              ethers.parseEther("0.1"),
              { value: Constants.savingFee }
            )
        );

        await expect(
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              ethers.parseEther("0.1"),
              { value: Constants.savingFee }
            )
        ).to
          .be.revertedWithCustomError(ChildBitsave, "InvalidSaving")

      });

      it("Should send gas fee to child contract", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);

        const userChildContractAddress = await bitsave
          .connect(optedUser).getUserChildContractAddress();

        const initialBalance = await ethers.provider.getBalance(userChildContractAddress);
        await (
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              savingData.amountEth,
              { value: Constants.savingFee + savingData.amountEth }
            )
        );
        const finalBalance = await ethers.provider.getBalance(userChildContractAddress);

        expect((finalBalance - initialBalance).valueOf())
          .to.be.greaterThan(Constants.savingFee.valueOf())
      });
    });
    describe("Events", function() {
      it("Should emit token withdrawal for not native token");
      it("Should emit saving created on successful saving", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);
        await expect(
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              savingData.amountEth,
              { value: Constants.savingFee + savingData.amountEth }
            )
        ).to.emit(bitsave, "SavingCreated")
          .withArgs(
            savingData.name,
            savingData.amountEth,
            ethers.ZeroAddress
          );

      });
    })
  })

  describe("Increment savings", function() {
    const savingData = {
      name: "Hospital Fee",
      maturityTime: Math.round(Date.now() / 1000 + 3000).toString(),
      penaltyPercentage: ethers.toBigInt(1),
      amountEth: ethers.parseEther("0.1"),
      incrementValue: ethers.parseEther("0.06")
    }

    describe("Actions", function() {
      it("Should increment savings value", async function() {
        const { bitsave, optedUser, } = await loadFixture(deployBitsave);

        const userChildContractAddress = await bitsave
          .connect(optedUser).getUserChildContractAddress();

      const c1 =
          await ethers.provider.getBalance(userChildContractAddress);

        console.log("c1", c1)

        await (
          bitsave.connect(optedUser)
            .createSaving(
              savingData.name,
              savingData.maturityTime,
              savingData.penaltyPercentage,
              false,
              ethers.ZeroAddress,
              savingData.amountEth,
              { value: savingData.amountEth }
            )
        );

        const contractInitialBalance =
          await ethers.provider.getBalance(userChildContractAddress);

        console.log("c2", contractInitialBalance)

        await (
          bitsave.connect(optedUser).incrementSaving(
            savingData.name,
            ethers.ZeroAddress,
            ethers.parseEther("0"),
            {value: savingData.incrementValue}
          )
        )

        const contractFinalBalance = 
          await ethers.provider.getBalance(userChildContractAddress);

        console.log("c3", contractFinalBalance)

        expect(contractFinalBalance - contractInitialBalance)
          .greaterThanOrEqual(savingData.incrementValue)

      });
      it("Should revert on invalid savings");
    })

    describe("Events", function() {

    })
  })

  describe("Withdraw savings", function() {
    describe("Actions", function() {
      it("Should withdraw savings back", async function() {
        const { bitsave, optedUser } = await loadFixture(deployBitsave);
        const myBalance = await ethers.provider.getBalance(optedUser);

      });
      it("Should revert on invalid savings withdrawal");
      // TODO:
      it("Should clean up funds on child contract");
    })

    describe("Events", function() {

    })
  })


  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);
  //
  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });
  //
  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);
  //
  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });
  //
  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });
  //
  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });
  //
  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
