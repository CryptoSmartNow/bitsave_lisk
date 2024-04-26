import { ethers } from "hardhat";

export const Constants = {
  stableCoin: "0x55d398326f99059ff775485246999027b3197955",
  masterAddress: "",
  csToken: ethers.ZeroAddress,
  initialBalance: ethers.parseEther("0.1"),
  DAIAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
  joinFee: ethers.parseEther("0.05"),
  savingFee: ethers.parseEther("0.001")
}

