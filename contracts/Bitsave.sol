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
    // *** Fountain ***
    uint256 public fountain;

    // *** Storage ***
    mapping(address => address) addressToUserBS;
    uint256 public userCount;
    // *** Storage requiring house modifiers ***
    uint256 public currentVaultState;
    uint256 public currentTotalValueLocked;

    // *** savings values ***
    uint256 public JoinLimitFee = 0.0001 ether;
    uint256 public SavingFee = 0.0001 ether;
    uint256 public ChildContractGasFee = SavingFee / 20;

    constructor(address _stableCoin, address _csToken) payable {
        stableCoin = IERC20(_stableCoin);
        csToken = IERC20(_csToken);
        masterAddress = msg.sender;
        rewardPool = 0;
        userCount = 0;
        // initial values
        currentVaultState = 14_000_000;
        currentTotalValueLocked = 100_000;
        fountain = msg.value;
    }

    modifier inhouseOnly() {
        if (msg.sender != masterAddress) {
            revert BitsaveHelperLib.MasterCallRequired();
        }
        _;
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
        address ownerAddress = msg.sender;
        address currAddr = addressToUserBS[ownerAddress];
        if (currAddr != address(0)) {
            return currAddr;
        }
        if (msg.value < JoinLimitFee)
            revert BitsaveHelperLib.AmountNotEnough();
        // deploy child contract for user
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
    ) public payable fromABitsaveChildOnly(ownerAddress) returns (bool) {
        // check amount sent
        // if (amount < poolFee) revert BitsaveHelperLib.AmountNotEnough();
        // retrieve stable coin used from owner address
        return BitsaveHelperLib.retrieveToken(
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

    /// Edit internal vault data
    function editInternalData(
        uint _newCurrentVaultState,
        uint _newTotalValueLocked,
        address _newCsToken
    ) public inhouseOnly {
        currentVaultState = _newCurrentVaultState;
        currentTotalValueLocked = _newTotalValueLocked;
        if (_newCsToken != address(0)) {
            csToken = IERC20(_newCsToken);
        }
    }

    /// Edit internal stablecoin data
    function editStableCoin(
        address _newStableCoin
    ) public inhouseOnly {
        if (_newStableCoin != address(0)) {
            stableCoin = IERC20(_newStableCoin);
        }
    }

    /// Edit internal vault data
    function editFees(
        uint _joinFee,
        uint _savingFee
    ) public inhouseOnly {
        if (_joinFee != 0) {
            JoinLimitFee = _joinFee;
        }
        if(_savingFee != 0) {
            SavingFee = _savingFee;
            ChildContractGasFee = _savingFee / 20;
        }
    }

    function dripFountain() public inhouseOnly {
        // send balance - fountain to masterAddress
        uint256 balance = address(this).balance;
        if (balance > fountain) {
            payable(masterAddress).transfer(balance - fountain);
        }
    }

    function handleNativeSaving(
        uint amount,
        address tokenToSave,
        address userChildContractAddress
    ) private returns(uint) {
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
        return amount;
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

        // Handle token sent
        uint amountRetrieved = handleNativeSaving(
            amount,
            tokenToSave,
            userChildContractAddress
        );

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
                ChildContractGasFee + amountRetrieved : ChildContractGasFee
            }(
            nameOfSaving,
            maturityTime,
            block.timestamp, // current time
            penaltyPercentage,
            tokenToSave,
            amountRetrieved,
            safeMode,
            currentVaultState,
            currentTotalValueLocked
        );

        // emit saving created
        emit BitsaveHelperLib.SavingCreated(
            nameOfSaving,
            amountRetrieved,
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
        // if (!isNativeToken) {
        //     // approve child contract withdrawing token
        //     require(
        //         BitsaveHelperLib.approveAmount(
        //             userChildContractAddress,
        //             savingPlusAmount,
        //             tokenToRetrieve
        //         ),
        //         "Savings invalid"
        //     );
        // } else {
        //     savingPlusAmount = msg.value;
        // }

        uint amountRetrieved = handleNativeSaving(
            amount,
            tokenToRetrieve,
            userChildContractAddress
        );
        // call withdrawSavings

        userChildContract.incrementSaving{
                value: isNativeToken ?
                ChildContractGasFee + savingPlusAmount : ChildContractGasFee
            }(nameOfSavings, amountRetrieved, currentVaultState, currentTotalValueLocked);
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

