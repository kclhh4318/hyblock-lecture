const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiBetERCExp Contract", function () {
  let Token;
  let token;
  let MultiBetERCExp;
  let multiBetERCExp;
  let owner;
  let addr1;
  let addr2;
  let addr3;

  const INITIAL_SUPPLY = ethers.parseEther("1000000"); // 1M tokens
  const BET_AMOUNT = ethers.parseEther("100"); // 100 tokens for betting

  beforeEach(async function () {
    // Deploy TestToken
    Token = await ethers.getContractFactory("TestToken");
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    token = await Token.deploy(INITIAL_SUPPLY);
    await token.waitForDeployment();

    // Deploy MultiBetERCExp with token address
    MultiBetERCExp = await ethers.getContractFactory("MultiBetERCExp");
    multiBetERCExp = await MultiBetERCExp.deploy(token.target);
    await multiBetERCExp.waitForDeployment();

    // Distribute tokens to test addresses
    await token.transfer(addr1.address, ethers.parseEther("10000"));
    await token.transfer(addr2.address, ethers.parseEther("10000"));
    await token.transfer(addr3.address, ethers.parseEther("10000"));

    // Approve MultiBetERCExp to spend tokens
    await token.connect(addr1).approve(multiBetERCExp.target, ethers.parseEther("10000"));
    await token.connect(addr2).approve(multiBetERCExp.target, ethers.parseEther("10000"));
    await token.connect(addr3).approve(multiBetERCExp.target, ethers.parseEther("10000"));
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await multiBetERCExp.owner()).to.equal(owner.address);
    });

    it("Should set the correct token address", async function () {
      expect(await multiBetERCExp.hyblockToken()).to.equal(token.target);
    });
  });

  describe("Creating Bets", function () {
    it("Owner can create a bet", async function () {
      const options = ["Option1", "Option2"];
      await expect(multiBetERCExp.createBet("Test Topic", options))
        .to.emit(multiBetERCExp, "BetCreated")
        .withArgs(0, "Test Topic", options);

      const betInfo = await multiBetERCExp.getBet(0);
      expect(betInfo.topic).to.equal("Test Topic");
      expect(betInfo.isResolved).to.be.false;
    });

    it("Non-owner cannot create a bet", async function () {
      const options = ["Option1", "Option2"];
      await expect(
        multiBetERCExp.connect(addr1).createBet("Test Topic", options)
      ).to.be.revertedWith("Only the owner can perform this action");
    });
  });

  describe("Placing Bets", function () {
    beforeEach(async function () {
      await multiBetERCExp.createBet("Test Topic", ["Option1", "Option2", "Option3"]);
    });

    it("Users can place bets with tokens", async function () {
      const initialBalance = await token.balanceOf(addr1.address);
      
      await expect(multiBetERCExp.connect(addr1).placeBet(0, "Option1", BET_AMOUNT))
        .to.emit(multiBetERCExp, "BetPlaced")
        .withArgs(0, addr1.address, BET_AMOUNT, "Option1");

      const finalBalance = await token.balanceOf(addr1.address);
      expect(initialBalance - finalBalance).to.equal(BET_AMOUNT);

      const [options, betAmounts] = await multiBetERCExp.getBetOptionInfos(0);
      expect(betAmounts[0]).to.equal(BET_AMOUNT);
    });

    it("Cannot place bet without approval", async function () {
      await token.connect(addr1).approve(multiBetERCExp.target, 0);
      
      // ERC20 컨트랙트의 custom error를 사용
      await expect(
        multiBetERCExp.connect(addr1).placeBet(0, "Option1", BET_AMOUNT)
      ).to.be.revertedWithCustomError(token, "ERC20InsufficientAllowance");
    });

    it("Cannot place bet with zero amount", async function () {
      await expect(
        multiBetERCExp.connect(addr1).placeBet(0, "Option1", 0)
      ).to.be.revertedWith("Bet amount must be greater than zero");
    });
  });

  describe("Resolving Bets", function () {
    beforeEach(async function () {
      await multiBetERCExp.createBet("Test Topic", ["Option1", "Option2"]);
      await multiBetERCExp.connect(addr1).placeBet(0, "Option1", BET_AMOUNT);
      await multiBetERCExp.connect(addr2).placeBet(0, "Option2", BET_AMOUNT);
    });

    it("Owner can resolve bet and winners receive rewards", async function () {
      const initialBalance = await token.balanceOf(addr1.address);
      
      await multiBetERCExp.resolveBet(0, "Option1");
      
      const finalBalance = await token.balanceOf(addr1.address);
      expect(finalBalance - initialBalance).to.equal(BET_AMOUNT * 2n);

      const betInfo = await multiBetERCExp.getBet(0);
      expect(betInfo.isResolved).to.be.true;
      expect(betInfo.winningOption).to.equal("Option1");
    });

    it("Losers don't receive rewards", async function () {
      const initialBalance = await token.balanceOf(addr2.address);
      
      await multiBetERCExp.resolveBet(0, "Option1");
      
      const finalBalance = await token.balanceOf(addr2.address);
      expect(finalBalance).to.equal(initialBalance);
    });
  });

  describe("User Bet Information", function () {
    beforeEach(async function () {
      await multiBetERCExp.createBet("Test Topic", ["Option1", "Option2"]);
      await multiBetERCExp.connect(addr1).placeBet(0, "Option1", BET_AMOUNT);
    });

    it("Should return correct user bet info", async function () {
      const [optionIndexes, betAmounts] = await multiBetERCExp.getUserBet(0, addr1.address);
      expect(optionIndexes[0]).to.equal(0);
      expect(betAmounts[0]).to.equal(BET_AMOUNT);
    });

    it("Should return empty arrays for users who haven't bet", async function () {
      const [optionIndexes, betAmounts] = await multiBetERCExp.getUserBet(0, addr2.address);
      expect(optionIndexes.length).to.equal(0);
      expect(betAmounts.length).to.equal(0);
    });
  });
});