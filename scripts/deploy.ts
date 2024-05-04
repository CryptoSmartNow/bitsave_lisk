import { ethers } from 'hardhat';

async function main() {
  const bitsave = await ethers.deployContract('Bitsave');

  await bitsave.waitForDeployment();

  console.log('Bitsave Contract Deployed at ' + bitsave.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
