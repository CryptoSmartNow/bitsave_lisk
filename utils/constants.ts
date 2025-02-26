import { ethers } from "hardhat";

export const Constants = {
  stableCoin: "0xac485391EB2d7D88253a7F1eF18C37f4242D1A24", // usdt lisk
  stableCoinName: "usdt-lisk",
  masterAddress: "0x125629FAab442e459C1015FCBa50499D0aAB8EE0",
  csToken: ethers.ZeroAddress, // For bitsave token point system
  initialBalance: ethers.parseEther("0.000000001"),
  DAIAddress: ethers.ZeroAddress, // TODO: DAI Address
  joinFee: ethers.parseEther("0.0000001"),
  savingFee: ethers.parseEther("0.0000001")
}

