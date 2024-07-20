import { ethers } from 'hardhat';
import { Constants } from '../utils/constants';
import { pk_account, publicClient, walletClientL2 } from "../utils/client";
import { getContract } from 'viem'
import { bitsaveAbi } from '../artifacts/abi/bitsave'


const ct_address = '0x01f0443DaEC78fbaBb2D0927fEdFf5C20a4A39b5'

// 1. Create contract instance
const contract = getContract({
  address: '0x01f0443DaEC78fbaBb2D0927fEdFf5C20a4A39b5',
  abi: bitsaveAbi,
  // 1a. Insert a single client
  //client: publicClient,
  // 1b. Or public and/or wallet clients
  client: { public: publicClient, wallet: walletClientL2 }
})


async function main() {
  const logs = await contract.getEvents.Transfer()
  const userChildContractAddress = await contract.read.getUserChildContractAddress();
  // const joinBitsave = await contract.write.joinBitsave({
  //   value: 3
  // });

  const { request } = await publicClient.simulateContract({
    account: pk_account,
    address: ct_address,
    abi: bitsaveAbi,
    functionName: 'joinBitsave',
    args: [Constants.joinFee]
  })
  const res = await walletClientL2.writeContract(request)
  console.log("LOGS", logs);
  console.log("C Address", userChildContractAddress);
  console.log("JB", res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
