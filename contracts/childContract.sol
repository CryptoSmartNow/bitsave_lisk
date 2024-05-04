// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/bitsaveHelperLib.sol";
import "./Bitsave.sol";

contract ChildBitsave {

  // *** Contract parameters ***
  address payable public bitsaveAddress;
  IERC20 public stableCoin;
  address public ownerAddress;

  // *** Contract Storage ***

  // structure of saving data
  struct SavingDataStruct {
      bool isValid;
      uint256 amount;
      address tokenId;
      uint256 interestAccumulated;
      uint256 startTime;
      uint penaltyPercentage;
      uint256 maturityTime;
      bool isSafeMode;
  }

  // mapping of name of saving to individual saving
  mapping(string => SavingDataStruct) public savings;
  struct SavingsNamesObj {
      string[] savingsNames;
  }

  SavingsNamesObj private savingsNamesVar;

  constructor(address _ownerAddress, address _stableCoin) payable {
        // save bitsaveAddress first // todo: retrieve correct address
        bitsaveAddress = payable(msg.sender);
        // store owner's address
        ownerAddress = payable(_ownerAddress);
        // store stable coin
        stableCoin = IERC20(payable(_stableCoin));
  }

  modifier bitsaveOnly() {
    if (msg.sender != bitsaveAddress)
      revert BitsaveHelperLib.CallNotFromBitsave();
    _;
  }
  function addSavingName(string memory _name) private {
    savingsNamesVar.savingsNames.push(_name);
  }


  // Contract Getters
  function getSavingMode(string memory nameOfSaving) view external returns (bool) {
        return savings[nameOfSaving].isSafeMode;
  }

  function getSavingInterest(string memory nameOfSaving) view external returns (uint256) {
        return savings[nameOfSaving].interestAccumulated;
  }

  function getSavingTokenId(string memory nameOfSaving) view external returns (address) {
        return savings[nameOfSaving].tokenId;
  }

  function getSavingsNames() external view returns (SavingsNamesObj memory) {
    return savingsNamesVar;
  }


  function getSaving(
    string memory nameOfSaving
  ) public view returns (SavingDataStruct memory) {
      return savings[nameOfSaving];
  }

  // TODO: Funds cleanup functionalities


// function sendAsOriginalToken(
//         address originalToken,
//         uint amount,
//         address ownerAddress
//     ) public payable {
//         // check amount sent
//         // if (amount < poolFee) revert BitsaveHelperLib.AmountNotEnough();
//         // retrieve stable coin used from owner address
//         BitsaveHelperLib.retrieveToken(ownerAddress, address(stableCoin), amount);
//         // convert to original token using crossChainSwap()
//         // crossChainSwap(
//         //     stableCoin,
//         //     originalToken,
//         //     amount,
//         //     ownerAddress // send to owner address directly
//         // );
//     }
  
  // functionality to create savings
    function createSaving (
        string memory name,
        uint256 maturityTime,
        uint256 startTime,
        uint8 penaltyPercentage,
        address tokenId,
        uint256 amountToRetrieve,
        bool isSafeMode
    ) public payable bitsaveOnly returns (uint) {
        // ensure saving does not exist; ! todo: this wont work
        if (savings[name].isValid) revert BitsaveHelperLib.InvalidSaving();
        // check if end time valid
        if (maturityTime < startTime) revert BitsaveHelperLib.InvalidTime();
        if (maturityTime < block.timestamp) revert BitsaveHelperLib.InvalidTime();

        // calculate interest
        uint accumulatedInterest = BitsaveHelperLib.calculateInterest(
          amountToRetrieve
        ); // todo: create interest formulae
        uint256 savingsAmount = amountToRetrieve;

        if (isSafeMode) {
            BitsaveHelperLib.retrieveToken(
              bitsaveAddress,
              address(stableCoin),
              amountToRetrieve
            );
        }else {
          if (tokenId != address(0)) {
            BitsaveHelperLib.retrieveToken(
              bitsaveAddress,
              tokenId,
              amountToRetrieve
            );
          } else {
            // case native token
            savingsAmount = msg.value;
          }
        }

        // store saving to map of savings
        savings[name] = SavingDataStruct({
            amount : savingsAmount,
            maturityTime : maturityTime,
            interestAccumulated : accumulatedInterest,
            startTime : startTime,
            tokenId : tokenId,
            penaltyPercentage : penaltyPercentage,
            isSafeMode : isSafeMode,
            isValid : true
        });

        // addSavingName(name);
        addSavingName(name);

        emit BitsaveHelperLib.SavingCreated(
            name,
            amountToRetrieve,
            tokenId
        );

        return 1;
    }

    // functionality to add to savings
    function incrementSaving (
      string memory name,
      uint256 savingPlusAmount
    ) public payable bitsaveOnly returns (uint) {

        // fetch savings data
        SavingDataStruct storage toFundSavings = savings[name];
        if (!toFundSavings.isValid) revert BitsaveHelperLib.InvalidSaving();
        if (block.timestamp > toFundSavings.maturityTime) revert BitsaveHelperLib.InvalidTime();

        bool isNativeToken = toFundSavings.tokenId == address(0);

        // handle retrieving token from contract
        if (toFundSavings.isSafeMode) {
            BitsaveHelperLib.retrieveToken(
              bitsaveAddress,
                address(stableCoin),
                savingPlusAmount
            );
        }else {
          if (!isNativeToken) {
            BitsaveHelperLib.retrieveToken(
              bitsaveAddress,
                toFundSavings.tokenId,
                savingPlusAmount
            );
          } else {
            require(
              msg.value >= savingPlusAmount, 
              "Invalid saving increment value sent"
            );
            savingPlusAmount = msg.value;
          }
        }
               // calculate new interest
        uint recalculatedInterest = BitsaveHelperLib.calculateInterest(
          savingPlusAmount
        );
        toFundSavings.interestAccumulated = toFundSavings.interestAccumulated + recalculatedInterest;
        toFundSavings.amount = toFundSavings.amount + savingPlusAmount;

        // save new savings data
        savings[name] = toFundSavings;

        emit BitsaveHelperLib.SavingIncremented(
            name,
            savingPlusAmount,
            toFundSavings.amount,
            toFundSavings.tokenId
        );

        return toFundSavings.interestAccumulated;
    }

function withdrawSaving (string memory name) public payable bitsaveOnly returns (string memory) {
        SavingDataStruct storage toWithdrawSavings = savings[name];
        // check if saving exit
        if (!toWithdrawSavings.isValid) revert BitsaveHelperLib.InvalidSaving();
        uint amountToWithdraw = toWithdrawSavings.amount;
        Bitsave bitsave = Bitsave(bitsaveAddress);
        // check if saving is mature
        if (block.timestamp < toWithdrawSavings.maturityTime) {
            // remove penalty from savings
            amountToWithdraw = (
              toWithdrawSavings.amount * (100 - toWithdrawSavings.penaltyPercentage)
            ) / 100;
        }else {
          // TODO: handle interest point management
            // bitsave.handleUsersInterest(
            //     name,
            //     address(this),
            //     ownerAddress
            // );
        }

        // send the savings amount to withdraw
        address tokenId = toWithdrawSavings.tokenId;
        // function can be abstracted for sending token out
        if (toWithdrawSavings.isSafeMode) {
            // approve withdrawal from parent contract
            BitsaveHelperLib.approveAmount(
              bitsaveAddress,
              amountToWithdraw,
              address(stableCoin)
            );
            // call parent for conversion
            bitsave
                .sendAsOriginalToken(
                    tokenId,
                    amountToWithdraw,
                    ownerAddress
                );
        }else {
          if (tokenId == address(0)) {
            (bool sent, bytes memory data) =
              ownerAddress.call{value: amountToWithdraw}("");
            require(sent, "Couldn't send funds");
          } else {
            BitsaveHelperLib.transferToken(
                toWithdrawSavings.tokenId,
                ownerAddress,
                amountToWithdraw
            );

          }
        }
        // Delete savings; ensure saving is deleted/made invalid
        savings[name].isValid = false;

        emit BitsaveHelperLib.SavingWithdrawn(
            name
        );

        return "savings withdrawn successfully";
    }
}

