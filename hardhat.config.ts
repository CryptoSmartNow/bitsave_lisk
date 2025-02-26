import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require('dotenv').config();
require('./tasks')

const config: HardhatUserConfig = {
  solidity: "0.8.23",
  networks: {
    // for testnet
    'lisk-sepolia': {
      url: 'https://rpc.sepolia-api.lisk.com',
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 1000000000,
      timeout: 60000,
    },
    // 'mainnet'
    'lisk': {
      url: 'https://rpc.api.lisk.com',
      accounts: [process.env.PROD_WALLET_KEY as string],
      timeout: 60000,
    }
    // we can add base here
  },
  // Hardhat expects etherscan here, even if you're using Blockscout.
  etherscan: {
    // Use "123" as a placeholder, because Blockscout doesn't need a real API key, and Hardhat will complain if this property isn't set.
    apiKey: {
      "lisk-sepolia": "123",
      "lisk": "123"
    },
    customChains: [
      {
        network: "lisk-sepolia",
        chainId: 4202,
        urls: {
          apiURL: "https://sepolia-blockscout.lisk.com/api",
          browserURL: "https://sepolia-blockscout.lisk.com"
        }
      },
        {
          network: "lisk",
          chainId: 1135,
          urls: {
              apiURL: "https://blockscout.lisk.com/api",
              browserURL: "https://blockscout.lisk.com"
          }
      }
    ]
  },
  sourcify: {
    enabled: false
  },
};


export default config;
