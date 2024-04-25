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

  constructor(address _stableCoin, address _csToken) payable {
    stableCoin = IERC20(_stableCoin);
    csToken = IERC20(_csToken);
    masterAddress = msg.sender;
    rewardPool = 0;
    userCount = 0;
  }

  modifier registeredOnly(address sender) {
    require(
      addressToUserBS[sender] != address(0),
      "User is not registered"
    );
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

    // function createSaving(
    //     address ownerAddress,
    //     string memory nameOfSaving,
    //     uint256 maturityTime,
    //     uint256 startTime,
    //     uint8 penaltyPercentage,
    //     // safe/risk mode
    //     bool safeMode,
    //     address tokenToSave,
    //     uint amount
    // ) internal registeredOnly(ownerAddress) {
    //     if (block.timestamp > maturityTime)
    //         revert BitsaveHelperLib.InvalidTime();
    //
    //     address savingToken = tokenToSave;
    //     // uint amountOfWeiSent;
    //     uint amountToSave = amount;
    //     // user's child contract address
    //     address payable userChildContractAddress = getUserChildContractAddress(
    //         ownerAddress
    //     );
    //
    //     // functionality for creating savings
    //     // if (safeMode) {
    //     //     amountToSave = crossChainSwap(
    //     //         savingToken,
    //     //         stableCoin,
    //     //         amount,
    //     //         address(this)
    //     //     );
    //     //     savingToken = stableCoin;
    //     // }
    //
    //     // Initialize user's child contract
    //     // userChildContract = UserContract(userChildContractAddress);
    //     // approve child contract withdrawing token
    //     // uint actualSaving = BitsaveHelperLib.approveAmount(
    //     //     userChildContractAddress,
    //     //     amountToSave,
    //     //     savingToken
    //     // );
    //
    //     // userChildContract.createSaving(
    //     //     nameOfSaving,
    //     //     maturityTime,
    //     //     startTime,
    //     //     penaltyPercentage,
    //     //     tokenToSave,
    //     //     actualSaving,
    //     //     safeMode
    //     // );
    // }

  receive() external payable {}

  // ---------- Private functions ---------------
 function getUserChildContractAddress(
        address myAddress
    ) internal view returns (address payable) {
        return payable(addressToUserBS[myAddress]);
    }

}

