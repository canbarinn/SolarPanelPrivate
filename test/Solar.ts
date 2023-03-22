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
    ); // you may not be able to directly use "=" here. if not, try using the receipt.

    return projectID;
  };

  beforeEach(async () => {
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!
    // ** I EXPECT THIS TO WORK BEFORE EVERY "it",
    // IF IT DOESN'T, YOU CAN DELETE "describe"s
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!

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
    xit("only owner can create projects", async () => {
      await expect(solar.connect(accounts[0]).createProject(1, 1, 1, 1, 1)).to.be.revertedWith(
        "Caller is not the owner!"
      );
    });

    xit("project IDs increment sequentially", async () => {
      const tx = await solar.createProject(1, 1, 1, 1, 5);
      //console.log(tx);
      const receipt = await tx.wait();
      //console.log(receipt);
      const projectIdGetter1 = receipt.events[0].args[0].toString();
      //console.log(projectIdGetter1);

      const tx2 = await solar.createProject(2, 2, 2, 2, 2);
      //console.log(tx2);

      const receipt2 = await tx2.wait();

      const projectIdGetter2 = receipt2.events[0].args[0].toString();
      //console.log(projectIdGetter2);

      await expect(+projectIdGetter1 + 1).to.be.eq(+projectIdGetter2);
      // console.log(receipt.events[0].args[0].toString());
    });
  });
  describe("Investor actions", () => {
    xit("investor can't invest more than their balance", async () => {
      const tx = await solar.createProject(1, 1, 1, 1, 1);
      //console.log(tx);
      const receipt = await tx.wait();
      //console.log(receipt.events);
      const projectIdGetter = receipt.events[0].args[0].toString();

      const balance = await token.balanceOf(accounts[0].address);
      const investAmount = balance.add(1);

      await token.connect(accounts[0]).approve(solar.address, investAmount);

      await expect(solar.connect(accounts[0]).invest(+projectIdGetter, investAmount)).to.be.revertedWith(
        "Insufficient balance!"
      );
    });
    xit("investor can't invest non-existing project", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("929"));

      const tx = await solar.createProject(1, 1, 1, 1, 1);
      const receipt = await tx.wait();

      const projectIdForTesting = receipt.events[0].args[0].toString();
      const nonExistingProjectId = +projectIdForTesting + 100000000000;
      //const receipt = await tx.wait();
      await expect(solar.connect(accounts[0]).invest(nonExistingProjectId, dollars("45"))).to.be.revertedWith(
        "The project with this ID is non-existent!"
      );
    });
    xit("investor can only invest before end time", async () => {});
    xit("investor can't invest if capacity is full", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("977"));
      //kapasite diye bir değişken koy +1ini ver
      const tx = await solar.createProject(1, 1, 1, 0, 1);

      const receipt = await tx.wait();

      const projectIdGetter = receipt.events[0].args[0].toString();

      await expect(solar.connect(accounts[0]).invest(projectIdGetter, dollars("27"))).to.be.revertedWith(
        "Capacity is full!"
      );
    });
    xit("investor can't invest more than 'maxInvestmentsPerInvestor'", async () => {
      // BU KODUN BAŞTAN AŞAĞI DÜZENLENMESİ LAZIM
      await token.connect(accounts[0]).approve(solar.address,dollars("1000"));
      const maxInvestmentsPerInvestor = 1;
      const tx = await solar.createProject(1,1,1,10000000000000,maxInvestmentsPerInvestor);
      const receipt = await tx.wait();
      await solar.connect(accounts[0]).invest(1, dollars("15"));

      expect( await
        solar.connect(accounts[0]).invest(1,dollars("15"))
        ).to.be.revertedWith( "You can't invest!");
    });
  });
  describe("Calculation", () => {
    it("profit calculation all projects tester", async () => {
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

      const amountOfProfitWithdraw = dollars("1");

      const firstProjectStartTimestamp = await(await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const tx1 = await solar.createProject(firstProjectAPR, firstProjectStartTimestamp, 20 * SECONDS_IN_A_YEAR, investmentCapacityOfProjects, maxInvestmentsPerInvestor);
      const receipt1 = await tx1.wait()
      const getFirstProjectID = receipt1.events[0].args[0].toString();
      await time.increase(1 * SECONDS_IN_A_YEAR);

      const secondProjectStartTimestamp = await(await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const tx2 = await solar.createProject(secondProjectAPR, secondProjectStartTimestamp, 50 * SECONDS_IN_A_YEAR, investmentCapacityOfProjects, maxInvestmentsPerInvestor);
      const receipt2 = await tx2.wait()
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

      expect(amountOfProfitWithdraw.add(afterWithdrawalBalanceOfInvestor).eq(initialBalance));



    });
    xit("withd test", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("1000"));

      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const SECONDS_IN_A_YEAR = 31536000;
      const tx = await solar.createProject(1000, startTimestamp, 20 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const tx2 = await solar.createProject(1000, startTimestamp, 20 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const tx3 = await solar.createProject(1070, startTimestamp, 20 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const tx4 = await solar.createProject(1400, startTimestamp, 50 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const tx5 = await solar.createProject(1900, startTimestamp, 50 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const tx6 = await solar.createProject(1900, startTimestamp, 30 * SECONDS_IN_A_YEAR, 100000000000, 1000000000000);
      const receipt = await tx.wait();
      const receipt2 = await tx2.wait();
      const receipt3 = await tx3.wait();
      const receipt4 = await tx4.wait();
      const receipt5 = await tx5.wait();
      const receipt6 = await tx6.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();
      const projectIdGetter2 = receipt2.events[0].args[0].toString();
      const projectIdGetter3 = receipt3.events[0].args[0].toString();
      const projectIdGetter4 = receipt4.events[0].args[0].toString();
      const projectIdGetter5 = receipt5.events[0].args[0].toString();
      const projectIdGetter6 = receipt6.events[0].args[0].toString();

      await solar.connect(accounts[0]).invest(projectIdGetter, 100000);
      await solar.connect(accounts[0]).invest(projectIdGetter3, 100000);
      await solar.connect(accounts[0]).invest(projectIdGetter5, 100000);
      await time.increase(12 * SECONDS_IN_A_YEAR);
      
      const profit1 = await solar
        .connect(accounts[0])
        .withdrawProfit(10000);
        // console.log("profit2", profit2);

      await solar.connect(accounts[0]).invest(projectIdGetter3, 100000);
      await solar.connect(accounts[0]).invest(projectIdGetter, 100000);
      await solar.connect(accounts[0]).invest(projectIdGetter6, 100000);
      await time.increase(3 * SECONDS_IN_A_YEAR);

      const profit2 = await solar
        .connect(accounts[0])
        .withdrawProfit(10000);
        // console.log("profit1", profit);
      const profit3 = await solar
        .connect(accounts[0])
        .withdrawProfit(10000);
        // console.log("profit1", profit);
      expect(await token.balanceOf(accounts[0].address)).to.be.eq(999430000);
    });
    xit("profit calculation is correct for batch projects profit withdrawal", async () => {
      await token.connect(accounts[0]).approve(solar.address, dollars("1000"));
      
      const startTimestamp = await (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
      const SECONDS_IN_A_YEAR = 31536000;
      const tx = await solar.createProject(1000, startTimestamp, 20 * SECONDS_IN_A_YEAR,1000000000000, 1000000000000 );
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      await solar.connect(accounts[0]).invest(projectIdGetter, dollars("100"));
      const accountBefore = await token.balanceOf(accounts[0].address);

      await time.increase(7 * SECONDS_IN_A_YEAR);

      const profit = solar.connect(accounts[0]).calculateProfit(projectIdGetter);
      await solar.connect(accounts[0]).withdrawProfit();
      expect(await token.balanceOf(accounts[0].address)).to.be.eq((+accountBefore) + (+profit));
    });
  });

})
