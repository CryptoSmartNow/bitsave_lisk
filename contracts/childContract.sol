// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract ChildBitsave {
  // *** Contract parameters ***
  address public stableCoin;
  address public ownerAddress;

  constructor(_initStableCoin, _ownerAddress) payable {
    stableCoin = _initStableCoin;
    ownerAddress = _ownerAddress;
  }

}

