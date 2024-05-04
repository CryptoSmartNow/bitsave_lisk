import { ethers } from 'hardhat';
import { Constants } from '../utils/constants';

async function main() {
  const Bitsave = await ethers.getContractFactory('Bitsave');
  const deployer = await ethers.getSigner(Constants.masterAddress);

  console.log(
    "Signer balance", 
    await deployer.getAddress(), 
    await ethers.provider.getBalance(deployer)
  );

  const bitsave = await Bitsave.deploy(
    Constants.stableCoin,
    Constants.csToken,
    {value: Constants.initialBalance}
  )

  console.log('Bitsave Contract Deployed at ' + await bitsave.getAddress());
  console.log(bitsave);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
