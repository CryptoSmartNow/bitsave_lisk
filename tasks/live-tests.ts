 // @ts-nocheck

import { task } from "hardhat/config";
import { pk_account, publicClient, walletClientL2 } from "../utils/client";
import { getContract } from 'viem'
require("@nomicfoundation/hardhat-toolbox");
import { bitsaveAbi } from '../artifacts/abi/bitsave'
import { erc20Abi } from '../artifacts/abi/erc20'
import { Constants } from "../utils/constants";


const ct_address = '0x0C4A310695702ed713BCe816786Fcc31C11fe932'

const lsk_token = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
// const lsk_token = "0xac485391EB2d7D88253a7F1eF18C37f4242D1A24"

const savingName = "Xsavy"

// 1. Create contract instance
const contract = getContract({
  address: ct_address,
  abi: bitsaveAbi,
  // 1a. Insert a single client
  //client: publicClient,
  // 1b. Or public and/or wallet clients
  client: { public: publicClient, wallet: walletClientL2 }
})

const erc20Contract = getContract({
  address: lsk_token,
  abi: erc20Abi,
  // 1a. Insert a single client
  //client: publicClient,
  // 1b. Or public and/or wallet clients
  client: { public: publicClient, wallet: walletClientL2 }
})

task("approve-bitsave", "Handles erc20 approval bitsave").setAction(async () => {
  const logs = await contract.getEvents.Transfer()
  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: lsk_token,
    abi: erc20Abi,
    functionName: 'approve',
  args: [
    ct_address,
    ethers.parseEther("1")
      ],
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address");
  console.log("JB", res);
});

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
      savingName,
      Math.round(Date.now() / 1000 + 3_000_000).toString(),
      ethers.toBigInt(1),
      false,
      lsk_token,
      ethers.parseEther("0.0001"),
    ],
    value: ethers.parseEther("0.0001")
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
      savingName,
      lsk_token,
      // ethers.ZeroAddress,
      ethers.parseEther("0.22"),
    ],
    value: ethers.parseEther("0.00003")
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
      savingName,
    ],
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
});


