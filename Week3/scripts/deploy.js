require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  // 스마트 컨트랙트 가져오기
  const MultiBet = await ethers.getContractFactory("MultiBetERC");
  const multiBet = await MultiBet.deploy();
  await multiBet.waitForDeployment(); // 변경된 메서드

  console.log("Contract is deployed to:", multiBet.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
