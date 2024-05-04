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
  uint256 public constant JoinLimitFee = 0.0001 ether;
  uint256 public constant SavingFee = 0.0001 ether;
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

  modifier fromABitsaveChildOnly(address childOwnerAddress) {
    address fetchedChildAddress = addressToUserBS[childOwnerAddress];
    if (
      fetchedChildAddress == address(0) // checks that the child contract exists
      || // could be merged into one check but for readability
      fetchedChildAddress != msg.sender // and that the child contract sent the request
    ) {
      revert BitsaveHelperLib.CallNotFromBitsave();
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

    function sendAsOriginalToken(
        address originalToken,
        uint amount,
        address ownerAddress
    ) public payable fromABitsaveChildOnly(ownerAddress) {
        // check amount sent
        // if (amount < poolFee) revert BitsaveHelperLib.AmountNotEnough();
        // retrieve stable coin used from owner address
        BitsaveHelperLib.retrieveToken(
          msg.sender,
          address(stableCoin), amount
        );
        // convert to original token using crossChainSwap()
        // crossChainSwap(
        //     stableCoin,
        //     originalToken,
        //     amount,
        //     ownerAddress // send to owner address directly
        // );
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

      // NOTE: For now, no safeMode since no swap contract
      if (safeMode) {
        revert BitsaveHelperLib.NotSupported("No safe mode yet!"); 
      }

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

  ///
    /// INCREMENT SAVING
    ///    the amount to add to saving
    ///
    ///    string nameOfSaving
    ///
    function incrementSaving(
        string memory nameOfSavings,
        address tokenToRetrieve,
        uint256 amount
    ) public payable registeredOnly(msg.sender) {
        // initialize userChildContract
        address payable userChildContractAddress = payable(
            addressToUserBS[msg.sender]
        );
      ChildBitsave userChildContract = ChildBitsave(userChildContractAddress);

      address savingToken = userChildContract.getSavingTokenId(nameOfSavings);
      bool isNativeToken = savingToken == address(0);
        // todo: perform amount conversion and everything
        uint savingPlusAmount = amount;
        // todo: check savings detail by reading the storage of userChildContract
        bool isSafeMode = userChildContract.getSavingMode(nameOfSavings);
        if (isSafeMode) {
            // savingPlusAmount = crossChainSwap(
            //     userChildContract.getSavingTokenId(nameOfSavings),
            //     stableCoin,
            //     savingPlusAmount,
            //     address(this)
            // );
            tokenToRetrieve = address(stableCoin);

        }
        if (!isNativeToken) {
          // approve child contract withdrawing token
          require(
            BitsaveHelperLib.approveAmount(
              userChildContractAddress,
              savingPlusAmount,
              tokenToRetrieve
            ),
            "Savings invalid"
          );
        } else {
          savingPlusAmount = msg.value;
        }
        // call withdrawSavings
        
        userChildContract.incrementSaving{
          value: isNativeToken ? 
          ChildContractGasFee + savingPlusAmount : ChildContractGasFee
        }(nameOfSavings, amount);
    }

/// WITHDRAW savings
    ///
    ///    string nameOfSaving
    ///
    function withdrawSaving(
        string memory nameOfSavings
    ) public registeredOnly(msg.sender) returns (bool) {
        // initialize user's child userChildContract
        ChildBitsave userChildContract = ChildBitsave(payable(addressToUserBS[msg.sender]));
        // call withdraw savings fn
        userChildContract.withdrawSaving(nameOfSavings);
        return true;
    }

  receive() external payable {}

  // ---------- Private functions ---------------
 function getUserChildContractAddress(
        address myAddress
    ) internal view returns (address payable) {
        return payable(addressToUserBS[myAddress]);
    }

}

