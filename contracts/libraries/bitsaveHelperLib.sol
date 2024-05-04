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
    error NotSupported(string);
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
        // approveAmount(toApproveUserAddress, amountToWithdraw, targetToken),
        IERC20(targetToken).allowance(
          toApproveUserAddress,
          address(this)
        ) >= amountToWithdraw,
        "Token could not be withdrawn"
      );
      return IERC20(targetToken).transferFrom(
        toApproveUserAddress,
        address(this),
        amountToWithdraw
      );
    }

    // TODO: integrate bitsave interest calculator
    function calculateInterest(
      uint256 amount
      // uint256 currBitsPointValue
    ) pure internal returns (uint accumulatedInterest) {
      accumulatedInterest = amount / 100;
    }

    function transferToken(
        address token,
        address recipient,
        uint amount
    ) internal {
        IERC20 Token = IERC20(token);

        // convert address to Byte
        Token.transfer(recipient, amount);

        emit TokenWithdrawal(
            address(this),
            recipient,
            amount
        );
    }

}
