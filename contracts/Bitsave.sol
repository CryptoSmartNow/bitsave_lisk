// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./childContract.sol";
import "./libraries/bitsaveHelperLib.sol";

// contract NFT is ERC721 {
//     uint256 public currentTokenId;
//
//     constructor() ERC721("NFT Name", "NFT") {}
//
//     function mint(address recipient) public returns (uint256) {
//         uint256 newItemId = ++currentTokenId;
//         _safeMint(recipient, newItemId);
//         return newItemId;
//     }
// }

contract Bitsave {

  // *** Contract parameters ***
  IERC20 public stableCoin;
  IERC20 public csToken;
  address public masterAddress;
  uint256 public rewardPool;

  // *** Storage ***
  mapping(address => address) addressToUserBS;
  uint256 public userCount;

  // *** Constants ***
  uint256 public constant JoinLimitFee = 0.05 ether;
  uint256 public constant SavingFee = 0.001 ether;
  uint256 public constant ChildContractGasFee = SavingFee / 20;

  constructor(address _stableCoin, address _csToken) payable {
    stableCoin = IERC20(_stableCoin);
    csToken = IERC20(_csToken);
    masterAddress = msg.sender;
    rewardPool = 0;
    userCount = 0;
  }

  modifier registeredOnly(address sender) {
    if (addressToUserBS[sender] == address(0)) {
      revert BitsaveHelperLib.UserNotRegistered();
    }
    _;
  }

  function joinBitsave(
    ) public payable returns (address) {
        if (msg.value < JoinLimitFee)
            revert BitsaveHelperLib.AmountNotEnough();
        // deploy child contract for user
        address ownerAddress = msg.sender;
        address userBSAddress = address(
            new ChildBitsave(msg.sender, address(stableCoin))
        );
        addressToUserBS[ownerAddress] = userBSAddress;
        userCount += 1;
        emit BitsaveHelperLib.JoinedBitsave(ownerAddress);
        return userBSAddress;
    }

    function getUserChildContractAddress() public view returns (address) {
        return addressToUserBS[msg.sender];
    }

    function createSaving(
        string memory nameOfSaving,
        uint256 maturityTime,
        uint8 penaltyPercentage,
        bool safeMode,
        address tokenToSave, // address 0 for native coin
        uint amount // discarded for native token; takes msg.value - SavingFee instead
    ) public registeredOnly(msg.sender) payable {

      if (msg.value < SavingFee)
          revert BitsaveHelperLib.NotEnoughToPayGasFee();

      if (block.timestamp > maturityTime)
          revert BitsaveHelperLib.InvalidTime();

      // user's child contract address
      address payable userChildContractAddress = getUserChildContractAddress(
          msg.sender
      );
  
      uint256 startTime = block.timestamp;

      // check if native currency saving 
      if (tokenToSave != address(0)) {
        // savingToken = tokenToSave;
        // amountToSave = amount;
        // perform withdrawal respective
        bool tokenHasBeenWithdrawn = BitsaveHelperLib
          .retrieveToken(
            msg.sender,
            tokenToSave,
            amount
          );
        if (!tokenHasBeenWithdrawn) {
          revert BitsaveHelperLib.CanNotWithdrawToken("Txn failed");
        }
        // let us know you've removed the savings
        emit BitsaveHelperLib.TokenWithdrawal(
          msg.sender,
          address(this),
          amount
        );
        // approve child contract withdrawing token
        require(
          BitsaveHelperLib.approveAmount(
            userChildContractAddress,
            amount,
            tokenToSave
          ),
          "Savings invalid"
        );
      } else {
        amount = msg.value - SavingFee;
      }

      // TODO:  perform conversion for stableCoin
      // functionality for safe mode
      // if (safeMode) {
      //     amountToSave = crossChainSwap(
      //         savingToken,
      //         stableCoin,
      //         amount,
      //         address(this)
      //     );
      //     savingToken = stableCoin;
      // }

      /// send savings request to child contract with a little gas 
      // Initialize user's child contract
      ChildBitsave userChildContract = ChildBitsave(userChildContractAddress);
      
      userChildContract.createSaving{
        value: tokenToSave == address(0) ? 
          ChildContractGasFee + amount : ChildContractGasFee
      }(
          nameOfSaving,
          maturityTime,
          startTime,
          penaltyPercentage,
          tokenToSave,
          amount,
          safeMode
      );

      // emit saving created 
      emit BitsaveHelperLib.SavingCreated(
        nameOfSaving,
        amount,
        tokenToSave
      );
  }

  receive() external payable {}

  // ---------- Private functions ---------------
 function getUserChildContractAddress(
        address myAddress
    ) internal view returns (address payable) {
        return payable(addressToUserBS[myAddress]);
    }

}

