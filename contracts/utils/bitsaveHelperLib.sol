// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
        bytes to,
        uint amount
    );
    event Received(address, uint);

    function approveAmount(
        address toApproveUserAddress,
        uint256 amountToApprove,
        address targetToken
      ) internal returns (uint256) {

        (address gasZRC20, uint256 gasFee) = IZRC20(targetToken)
          .withdrawGasFee();

        gasFee = gasFee * 2;

        if (gasZRC20 != targetToken) revert WrongGasContract();
        if (gasFee >= amountToApprove) revert NotEnoughToPayGasFee();

        uint256 actualSaving = amountToApprove - gasFee;

        IZRC20(targetToken).approve(targetToken, gasFee);
        IZRC20(targetToken).approve(toApproveUserAddress, actualSaving);
        return actualSaving;
      }

    function transferToken(
        address token,
        address recipient,
        uint amount
    ) internal {
        IZRC20 Token = IZRC20(token);
        (address gasZRC20, uint256 gasFee) = Token.withdrawGasFee();
        gasFee = gasFee * 2;
        // BUG: uses gasFee * 2
        if (gasZRC20 != token) revert WrongGasContract();
        if (gasFee > amount) revert NotEnoughToPayGasFee();
        // convert address to Byte
        bytes32 userAddressBytes32 = BytesHelperLib.addressToBytes(recipient);
        bytes memory userAddressBytes = BytesHelperLib.bytes32ToBytes(userAddressBytes32);
        Token.withdraw(
            userAddressBytes,
            amount
        );

        emit TokenWithdrawal(
            address(this),
            userAddressBytes,
            amount
        );
    }

}
