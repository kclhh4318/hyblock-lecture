const hre = require("hardhat");

async function main() {
  try {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying HYBLOCK Token with account:", deployer.address);
    
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("Account balance:", hre.ethers.formatEther(balance.toString()), "ETH");

    // Deploy the token contract
    const HYBLOCKToken = await hre.ethers.getContractFactory("HYBLOCKToken");
    const token = await HYBLOCKToken.deploy();
    await token.waitForDeployment();

    const tokenAddress = await token.getAddress();
    console.log("HYBLOCK Token deployed to:", tokenAddress);
    
    // Verify contract on Etherscan (if not on a local network)
    if (network.name !== "hardhat" && network.name !== "localhost") {
      console.log("Waiting for block confirmations...");
      await token.deploymentTransaction().wait(5);
      
      console.log("Verifying contract on Etherscan...");
      await hre.run("verify:verify", {
        address: tokenAddress,
        constructorArguments: [],
      });
    }

    // Log token details
    const name = await token.name();
    const symbol = await token.symbol();
    const totalSupply = await token.totalSupply();
    const decimals = await token.decimals();

    console.log("\nToken Details:");
    console.log("-------------");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Decimals:", decimals);
    console.log("Total Supply:", hre.ethers.formatEther(totalSupply), "HYB");
    
  } catch (error) {
    console.error("Error during deployment:", error);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});