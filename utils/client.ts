import { createPublicClient, createWalletClient, http, custom } from 'viem'
import { liskSepolia, sepolia, lisk, base } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts';
import { walletActionsL1, walletActionsL2 } from 'viem/op-stack';
// import { EthereumProvider } from '@walletconnect/ethereum-provider'
import { publicActionsL2 } from 'viem/op-stack'

export const publicClient = createPublicClient({
  chain: base,
  transport: http(),
}).extend(publicActionsL2());

const pv_key = process.env.WALLET_KEY as string;

export const walletClientL1 = createWalletClient({
  account: privateKeyToAccount(`0x${pv_key}`), 
  chain: base,
  transport: http()
}).extend(walletActionsL1());

// Wallet client for Lisk
export const walletClientL2 = createWalletClient({
  account: privateKeyToAccount(`0x${pv_key}`), 
  chain: base,
  transport: http()
}).extend(walletActionsL2());

export const pk_account = privateKeyToAccount(`0x${pv_key}`)

// eg: Metamask
// export const walletClient = createWalletClient({
//   chain: liskSepolia,
//   transport: custom(window.ethereum),
// })

// eg: WalletConnect
// const provider = await EthereumProvider.init({
//   projectId: "abcd1234",
//   showQrModal: true,
//   chains: [1],
// })

// export const walletClientWC = createWalletClient({
//   chain: liskSepolia,
//   transport: custom(provider),
// })
