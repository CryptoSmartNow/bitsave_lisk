// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library BitsaveHelperLib {
    // Constants
    uint256 public constant txnCharge = 0.02 ether;

    // Errors
    error WrongGasContract();
    error NotEnoughToPayGasFee();
    error AmountNotEnough();
    error InvalidTime();
    error UserNotRegistered();
    error InvalidSaving();
    error CanNotWithdrawToken(string);
    // child contract specific
    error CallNotFromBitsave();

    // Events
    event JoinedBitsave(
        address userAddress
    );
    event SavingCreated(
        string nameOfSaving,
        uint amount,
        address token
    );
    event SavingIncremented(
        string nameOfSaving,
        uint amountAdded,
        uint totalAmountNow,
        address token
    );
    event SavingWithdrawn(
        string nameOfSaving
    );
    event TokenWithdrawal(
        address indexed from,
        address to,
        uint amount
    );
    event Received(address, uint);

    function approveAmount(
        address toApproveUserAddress,
        uint256 amountToApprove,
        address targetToken
      ) internal returns (bool) {
        IERC20 token = IERC20(targetToken);
        return token.approve(toApproveUserAddress, amountToApprove);
      }

    function retrieveToken(
      address toApproveUserAddress, address targetToken, uint256 amountToWithdraw
    ) internal returns (bool) {
      // first request approval
      require(
        approveAmount(toApproveUserAddress, amountToWithdraw, targetToken),
        "Token could not be withdrawn"
      );
      return IERC20(targetToken).transferFrom(
        toApproveUserAddress,
        address(this),
        amountToWithdraw
      );
    }

    // TODO: integrate bitsave interest calculator
    function calculateInterest(uint256 amount) pure internal returns (uint accumulatedInterest) {
      accumulatedInterest = amount / 100;
    }

    // function transferToken(
    //     address token,
    //     address recipient,
    //     uint amount
    // ) internal {
    //     IZRC20 Token = IZRC20(token);
    //     (address gasZRC20, uint256 gasFee) = Token.withdrawGasFee();
    //     gasFee = gasFee * 2;
    //     // BUG: uses gasFee * 2
    //     if (gasZRC20 != token) revert WrongGasContract();
    //     if (gasFee > amount) revert NotEnoughToPayGasFee();
    //     // convert address to Byte
    //     bytes32 userAddressBytes32 = BytesHelperLib.addressToBytes(recipient);
    //     bytes memory userAddressBytes = BytesHelperLib.bytes32ToBytes(userAddressBytes32);
    //     Token.withdraw(
    //         userAddressBytes,
    //         amount
    //     );
    //
    //     emit TokenWithdrawal(
    //         address(this),
    //         userAddressBytes,
    //         amount
    //     );
    // }

}
