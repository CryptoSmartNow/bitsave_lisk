// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/bitsaveHelperLib.sol";

contract ChildBitsave {

  // *** Contract parameters ***
  address public bitsaveAddress;
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

  function getSavingsNames() external view returns (SavingsNamesObj memory) {
    return savingsNamesVar;
  }


  function getSaving(
    string memory nameOfSaving
  ) public view returns (SavingDataStruct memory) {
      return savings[nameOfSaving];
  }
  
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
}

