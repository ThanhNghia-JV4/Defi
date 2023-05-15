// const ethers = "hardhat";
async function main() {
  // const RewardToken = await ethers.getContractFactory("RewardToken");
  // const rewardToken = await RewardToken.deploy();

  // console.log("Deploying Staking Token....");
  // // We get the contract to deploy
  // await stakingToken.deployed();

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const RewardToken = await ethers.getContractFactory("RewardToken");
  const rewardToken = await RewardToken.deploy();

  console.log("Deployed to:", rewardToken.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});