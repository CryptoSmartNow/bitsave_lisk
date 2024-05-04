import { ethers } from "hardhat";

export const Constants = {
  stableCoin: "0x2728DD8B45B788e26d12B13Db5A244e5403e7eda", // usdt lisk
  stableCoinName: "usdt-lisk",
  masterAddress: "0x23D2d7CD86e9DeCA3b837400E6ffD490E2191cCD",
  csToken: ethers.ZeroAddress, // For bitsave token point system
  initialBalance: ethers.parseEther("0.01"),
  DAIAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
  joinFee: ethers.parseEther("0.0001"),
  savingFee: ethers.parseEther("0.0001")
}

