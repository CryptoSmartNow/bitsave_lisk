# Bitsave
Bitsave is a SaveFi protocol on the lisk blockchain providing a 
financial saving infrastructure for users and providing measures to escape
the volatile nature of the crypto market. 
The contract has an interest formula based on the bitsave protocol to 
reward users points that are not fixed but adjust based on market
values. Integrating this would be after the uniswap contract is in place and
bitsave token is available on the lisk blockchain.

> [!NOTE]
> Don't use safeMode for now since we don't have the uniswap contract

Deployer Address
`0x23D2d7CD86e9DeCA3b837400E6ffD490E2191cCD`

## Contract details
Contract address:
```
# Current:
0x1a8A45d8bD38D2D13598B988b6c2121C3FEd816d
# Old:
v0: 0x01f0443DaEC78fbaBb2D0927fEdFf5C20a4A39b5`  
```
Artifacts path : `artifacts/contracts/`


[Blockscout explorerer verified contract](https://sepolia-blockscout.lisk.com/address/0x01f0443DaEC78fbaBb2D0927fEdFf5C20a4A39b5?tab=contract)


# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

