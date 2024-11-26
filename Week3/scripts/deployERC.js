const HYBLOCK_TOKEN_ADDRESS = "0x220634d3d55DE21c5F0C5Ec37C1CC0c247dcc866";
const {ethers} = require("hardhat");
require("dotenv").config();

async function main(){
    const MultiBetERC = await ethers.getContractFactory("MultiBetERCExp");
    const multiBetERC = await MultiBetERC.deploy(HYBLOCK_TOKEN_ADDRESS);
    await multiBetERC.waitForDeployment();

    console.log("Contract is deployed to:", multiBetERC.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });