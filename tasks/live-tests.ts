 // @ts-nocheck

import { task } from "hardhat/config";
import { pk_account, publicClient, walletClientL2 } from "../utils/client";
import { getContract } from 'viem'
require("@nomicfoundation/hardhat-toolbox");
import { bitsaveAbi } from '../artifacts/abi/bitsave'


const ct_address = '0x1a8A45d8bD38D2D13598B988b6c2121C3FEd816d'

// 1. Create contract instance
const contract = getContract({
  address: '0x01f0443DaEC78fbaBb2D0927fEdFf5C20a4A39b5',
  abi: bitsaveAbi,
  // 1a. Insert a single client
  //client: publicClient,
  // 1b. Or public and/or wallet clients
  client: { public: publicClient, wallet: walletClientL2 }
})

task("join-bitsave", "Handles joining bitsave").setAction(async () => {
  const logs = await contract.getEvents.Transfer()
  const userChildContractAddress = await contract.read.getUserChildContractAddress();
  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: ct_address,
    abi: bitsaveAbi,
    functionName: 'joinBitsave',
    value: ethers.parseEther("0.0001")
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
});


task("create-saving", "Handles joining bitsave").setAction(async () => {
  const logs = await contract.getEvents.Transfer()
  const userChildContractAddress = await contract.read.getUserChildContractAddress();
  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: ct_address,
    abi: bitsaveAbi,
    functionName: 'createSaving',
    args: [
      "Home",
      Math.round(Date.now() / 1000 + 3000).toString(),
      ethers.toBigInt(1),
      false,
      ethers.ZeroAddress,
      ethers.parseEther("0.0005"),
    ],
    value: ethers.parseEther("0.0005")
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
});

task("increment-saving", "Handles incrementing saving").setAction(async () => {
  const logs = await contract.getEvents.Transfer()
  const userChildContractAddress = await contract.read.getUserChildContractAddress();
  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: ct_address,
    abi: bitsaveAbi,
    functionName: 'incrementSaving',
    args: [
      "Home",
      ethers.ZeroAddress,
      ethers.parseEther("0.0005"),
    ],
    value: ethers.parseEther("0.0005")
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
});

task("withdraw-saving", "Handles joining bitsave").setAction(async () => {
  const logs = await contract.getEvents.Transfer()
  const userChildContractAddress = await contract.read.getUserChildContractAddress();
  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: ct_address,
    abi: bitsaveAbi,
    functionName: 'withdrawSaving',
    args: [
      "Home",
    ],
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
});


