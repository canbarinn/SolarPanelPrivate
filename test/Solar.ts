import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {expect} from "chai";
import {ethers} from "hardhat";
import {MockToken, Solar} from "../typechain-types";
import {time} from "@nomicfoundation/hardhat-network-helpers";

describe("Solar", function () {
  let owner: SignerWithAddress;
  let accounts: SignerWithAddress[];

  let solar: Solar;
  let token: MockToken;

  let dollars = (amount: string) => {
    return ethers.utils.parseUnits(amount, 6);
  };

  let currentTimestamp = async () => {
    return (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
  };

  let createProject = async () => {
    const projectID = await solar.createProject(
      10,
      await currentTimestamp(),
      (await currentTimestamp()) + 60 * 60 * 24 * 365 * 15,
      dollars("50"),
      3
    );

    return projectID;
  };

  beforeEach(async () => {
    [owner, ...accounts] = await ethers.getSigners();

    const tokenFactory = await ethers.getContractFactory("MockToken");
    token = (await tokenFactory.deploy("MockToken", "Mock")) as MockToken;

    const solarFactory = await ethers.getContractFactory("Solar");
    solar = (await solarFactory.deploy(token.address)) as Solar;

    await token.mint(owner.address, dollars("1000"));
    await token.mint(accounts[0].address, dollars("1000"));
    await token.mint(solar.address, dollars("100000"));
  });
  describe("Owner actions", () => {
    it("only owner can create projects", async () => {
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;
      expect(
        solar
          .connect(accounts[0])
          .createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor)
      ).to.be.revertedWith("Caller is not the owner!");
    });

    it("project IDs increment sequentially", async () => {
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp1 = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp1, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter1 = receipt.events[0].args[0].toString();

      const startTimestamp2 = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

      const tx2 = await solar.createProject(Apr, startTimestamp2, projectDuration, capacity, maxInvestmentsPerInvestor);

      const receipt2 = await tx2.wait();

      const projectIdGetter2 = receipt2.events[0].args[0].toString();

      expect(+projectIdGetter1 + 1).to.be.eq(+projectIdGetter2);
    });
  });
  describe("Investor actions", () => {
    it("investor can't invest more than their balance", async () => {
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);

      const receipt = await tx.wait();

      const projectIdGetter = receipt.events[0].args[0].toString();

      const balance = await token.balanceOf(accounts[0].address);
      const investmentAmount = balance.add(1);

      expect(solar.connect(accounts[0]).invest(+projectIdGetter, investmentAmount)).to.be.revertedWith(
        "Insufficient balance!"
      );
    });
    it("investor can't invest non-existing project", async () => {
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();

      const projectIdForTesting = receipt.events[0].args[0].toString();
      const nonExistingProjectId = +projectIdForTesting + 1; // summing projectID with 1 so that we can get non-existing projectID

      const investmentAmount = dollars("45");
      expect(solar.connect(accounts[0]).invest(nonExistingProjectId, investmentAmount)).to.be.revertedWith(
        "The project with this ID is non-existent!"
      );
    });
    it("investor can only invest before end time", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("1000"));
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      await time.increaseTo(startTimestamp + projectDuration + 100); // investing after project is expired

      const investmentAmount = 100;

      expect(solar.connect(accounts[0]).invest(+projectIdGetter, investmentAmount)).to.be.revertedWith(
        "Project expired!"
      );
    });
    it("investor can't invest if capacity is full", async () => {
      token.connect(accounts[0]).approve(solar.address, dollars("1000"));
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("10");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      await solar.connect(accounts[0]).invest(projectIdGetter, capacity);

      const secondInvestmentAmount = 1;
      expect(solar.connect(accounts[0]).invest(projectIdGetter, secondInvestmentAmount)).to.be.revertedWith(
        "Capacity is full!"
      );
    });
    it("investor can't invest more than 'maxInvestmentsPerInvestor'", async () => {
      // BU KODUN BAŞTAN AŞAĞI DÜZENLENMESİ LAZIM
      await token.connect(accounts[0]).approve(solar.address, dollars("1000"));
      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      const investmentAmount = dollars("1");

      await solar.connect(accounts[0]).invest(projectIdGetter, investmentAmount);

      expect(solar.connect(accounts[0]).invest(projectIdGetter, investmentAmount)).to.be.revertedWith(
        "You can't invest!"
      );
    });
  });
  describe("Calculation", () => {
    it("profit calculation is correct for batch projects profit withdrawal", async () => {
      /* 
      Owner creates 2 projects with different durations and different start times. Same investor invest in each project twice. Time span 
      between investments for each projects is 12 years (therefore project durations should be more than 17 years for this particular test.). 
      After 5 years from the second investment, investor will withdraw amount of 2500. We will check if balance before withdrawal is equal to sum of given
      amount and new balance. 
       Note that, initial investment will be held by contrat forever.
      Investor only can withdraw profit. 
      First investments will be 12000, second investments will be 10000.
      Each project will have different APR.
      */
      await token.connect(accounts[0]).approve(solar.address, dollars("1000"));

      const SECONDS_IN_A_YEAR = 31536000;

      const firstProjectAPR = 1200;
      const secondProjectAPR = 1000;

      const firstInvestmentAmount = 12000;
      const secondInvestmentAmount = 10000;

      const investmentCapacityOfProjects = 100000000000;
      const maxInvestmentsPerInvestor = 1000000000000;

      const amountOfProfitWithdraw = 100;

      const firstProjectStartTimestamp = await (
        await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
      ).timestamp;
      const tx1 = await solar.createProject(
        firstProjectAPR,
        firstProjectStartTimestamp,
        20 * SECONDS_IN_A_YEAR,
        investmentCapacityOfProjects,
        maxInvestmentsPerInvestor
      );
      const receipt1 = await tx1.wait();
      const getFirstProjectID = receipt1.events[0].args[0].toString();
      await time.increase(1 * SECONDS_IN_A_YEAR);

      const secondProjectStartTimestamp = await (
        await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
      ).timestamp;
      const tx2 = await solar.createProject(
        secondProjectAPR,
        secondProjectStartTimestamp,
        50 * SECONDS_IN_A_YEAR,
        investmentCapacityOfProjects,
        maxInvestmentsPerInvestor
      );
      const receipt2 = await tx2.wait();
      const getSecondProjectID = receipt2.events[0].args[0].toString();

      const balanceOfContractBeforeInvestment = await token.balanceOf(solar.address);
      const balanceOfInvestorBeforeInvestment = await token.balanceOf(accounts[0].address);
      console.log("Balance of Solar contract before investor invest:", balanceOfContractBeforeInvestment);
      console.log("Balance of Investor before investor invest:", balanceOfInvestorBeforeInvestment);

      await solar.connect(accounts[0]).invest(getFirstProjectID, firstInvestmentAmount);
      await solar.connect(accounts[0]).invest(getSecondProjectID, secondInvestmentAmount);

      await time.increase(12 * SECONDS_IN_A_YEAR);

      await solar.connect(accounts[0]).invest(getFirstProjectID, secondInvestmentAmount);
      await solar.connect(accounts[0]).invest(getSecondProjectID, secondInvestmentAmount);

      await time.increase(5 * SECONDS_IN_A_YEAR);

      const balanceOfContractAfterInvestment = await token.balanceOf(solar.address);
      const balanceOfInvestorAfterInvestment = await token.balanceOf(accounts[0].address);
      console.log("Balance of Solar contract after investor invest:", balanceOfContractAfterInvestment);
      console.log("Balance of Investor after investor invest:", balanceOfInvestorAfterInvestment);

      const initialBalance = await token.connect(accounts[0]).balanceOf(accounts[0].address);

      const withdrawal = await solar.connect(accounts[0]).withdrawProfit(amountOfProfitWithdraw);

      console.log("withdrawal:", withdrawal);

      const afterWithdrawalBalanceOfInvestor = await token.balanceOf(accounts[0].address);
      const afterWithdrawalBalanceOfContract = await token.balanceOf(solar.address);
      console.log("Balance of Solar contract after investor withdraw:", afterWithdrawalBalanceOfInvestor);
      console.log("Balance of Investor after investor withdraw:", afterWithdrawalBalanceOfContract);

      expect(afterWithdrawalBalanceOfInvestor.add(amountOfProfitWithdraw).eq(initialBalance));
    });
    it("second half profit calculation is correct", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("10"));

      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("100");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      const investmentAmount = 1000;
      const profitAmountExpectedAfter15Years = 1375;

      await solar.connect(accounts[0]).invest(projectIdGetter, investmentAmount);

      await time.increase(15 * SECONDS_IN_A_YEAR);

      expect(await solar.connect(accounts[0]).calculateProfit(projectIdGetter)).eq(profitAmountExpectedAfter15Years);
    });
    it("first half profit calculation is correct", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("10000"));

      const SECONDS_IN_A_YEAR = 31536000;

      const Apr = 1000;
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const projectDuration = 20 * SECONDS_IN_A_YEAR;
      const capacity = dollars("10000");
      const maxInvestmentsPerInvestor = 1000;

      const tx = await solar.createProject(Apr, startTimestamp, projectDuration, capacity, maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      const investmentAmount = dollars("1000");
      const profitAmountExpectedAfter15Years = dollars("700");

      await solar.connect(accounts[0]).invest(projectIdGetter, investmentAmount);

      await time.increase(7 * SECONDS_IN_A_YEAR);

      expect(await solar.connect(accounts[0]).calculateProfit(projectIdGetter)).to.be.eq(
        profitAmountExpectedAfter15Years
      );
    });
  });
});
