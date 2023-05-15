// const ethers = "hardhat";

async function main() {
  const StakingToken = await ethers.getContractFactory("StakingToken");
  const stakingToken = await StakingToken.deploy(
    "0x319A1610890B8fBA9b57f7a21cD934cB6151c27D",
    1
  );

  console.log("Deploying Staking Token....");
  // We get the contract to deploy
  await stakingToken.deployed();

  console.log("Deployed to:", stakingToken.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});