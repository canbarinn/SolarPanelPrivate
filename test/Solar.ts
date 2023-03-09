import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MockToken, Solar } from "../typechain-types";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Solar", function () {
  let owner: SignerWithAddress;
  let accounts: SignerWithAddress[];

  let solar: Solar;
  let token: MockToken;

  let dollars = (amount: string) => {
    return ethers.utils.parseUnits(amount, 6);
  };

  let currentTimestamp = async () => {
    return (
      await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
    ).timestamp;
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
    await token.mint(solar.address, dollars("1000"));
  });
  describe("Owner actions", () => {
    it("only owner can create projects", async () => {
      // -------RECEIPT
      // const tx = await solar.createProject(1,1,1,1,1);
      // console.log(tx);
      // const receipt = await tx.wait();
      // console.log(receipt.events);

      // -------TRIAL1 (DID NOT WORK)
      //  const ownAct = await solar.connect(accounts[0]).createProject(1, 1, 1, 1, 1);
      //  await ownAct.wait();
      //  console.log(ownAct);
      //  expect(ownAct).to.be.revertedWith("Caller is not the owner!");

      await expect(solar.connect(accounts[0]).createProject(1,1,1,1,1)).to.be.revertedWith("Caller is not the owner!");

    });

    it("project IDs increment sequentially", async () => {

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

      await expect((+projectIdGetter1)+1).to.be.eq(+projectIdGetter2);
      // console.log(receipt.events[0].args[0].toString());

    });
  });
  describe("Investor actions", () => {
    it("investor can't invest more than their balance", async () => {

      const tx = await solar.createProject(1, 1, 1, 1, 1);
      //console.log(tx);
      const receipt = await tx.wait();
      //console.log(receipt.events);
      const projectIdGetter = receipt.events[0].args[0].toString();
      
      const balance = await token.balanceOf(accounts[0].address);
      const investAmount = balance.add(1);

      await token.connect(accounts[0]).approve(solar.address, investAmount);
      
      await expect(
        solar.connect(accounts[0]).invest((+projectIdGetter), investAmount)
        ).to.be.revertedWith("Insufficient balance!");



      // const time = (
      //   await solar.getInvestmentTime(accounts[0].address, 1)
      // ).toString();
      // await console.log("time is " + time);

      

      // -----------------TRY 2 (solar.addresse mint ettim, parayı buraya yolluyorum)
      // await token.approve(solar.address, dollars("999"));
      // await token.connect(accounts[0]).approve(solar.address, dollars("999"));
      // await solar.connect(accounts[0]).invest(1, dollars("72"));

      // await console.log((await token.balanceOf(solar.address)).toString());
      // const balance = (
      //   await solar.balanceOfInvestor(accounts[0].address, 1)
      // ).toString();
      // await console.log(await balance);

      // const time = (await solar.getInvestmentTime(accounts[0].address, 1)).toString();
      //   await console.log("time is " + time);

      


    });
    it("investor can't invest non-existing project", async () => {

      await token.connect(accounts[0]).approve(solar.address,dollars("929"));

      const tx = await solar.createProject(1,1,1,1,1);
      const receipt = await tx.wait();

      const projectIdForTesting = receipt.events[0].args[0].toString();
      const nonExistingProjectId = (+projectIdForTesting + 1000000);
      //const receipt = await tx.wait();
      await expect( solar.connect(accounts[0]).invest(nonExistingProjectId, dollars("45"))).to.be.revertedWith("The project with this ID is non-existent!");
      

    });
    it("investor can only invest before end time", async () => {});
    it("investor can't invest if capacity is full", async () => {
      await token.connect(accounts[0]).approve(solar.address,dollars("977"));
      //kapasite diye bir değişken koy +1ini ver
      const tx = await solar.createProject(1,1,1,0,1);
  
      const receipt = await tx.wait();

      const projectIdGetter = receipt.events[0].args[0].toString();

      await expect(
        solar.connect(accounts[0]).invest(projectIdGetter, dollars("27"))
        ).to.be.revertedWith("Capacity is full!");

    });
    it("investor can't invest more than 'maxInvestmentsPerInvestor'", async () => {

      //BU KODUN BAŞTAN AŞAĞI DÜZENLENMESİ LAZIM


      // await token.connect(accounts[0]).approve(solar.address,dollars("1000"));
      // const tx = await solar.createProject(5,5,5,5,5);


      // const receipt = await tx.wait();


      // const maxInvestmentsGetter = receipt.events[0].args[1].toString();

      // const higherInvestment = (+maxInvestmentsGetter + 100 )

      // await expect(
      //   solar.connect(accounts[0]).invest(1,higherInvestment)
      //   ).to.be.revertedWith( "You should invest less amount!");
     
    });
  });
  describe("Calculation", () => {
    it("profit calculation is correct for single project profit withdrawal", async () => {
      //kapasite diye bir değişken koy +1ini ver
      await token.connect(accounts[0]).approve(solar.address, dollars("999"));
      const secondsInAYear = 31536000;
      const tx = await solar.createProject(100,100,100,1000000000000,1000000000000);
      const receipt = await tx.wait();
      const projectIdGetter = receipt.events[0].args[0].toString();

      await solar.connect(accounts[0]).invest(+projectIdGetter, dollars("100"));
      //await solar.connect(accounts[0]).invest(+projectIdGetter, dollars("1"));
      const current = await time.increase(secondsInAYear * 15);

      
      const calculation = await solar.connect(accounts[0]).calculationTester(100, current);
      console.log(calculation);
      // expect(await +calculation ).to.be.eq(4000);


    });
    it("profit calculation is correct for batch projects profit withdrawal", async () => {});
  });

  //CAN:For testing purposes
  describe("All entries are complete.", () => {});
  //CAN:For testing purposes
  /**
   * Side note: we can set the end time for projects 15 years after than start date
   * Business logic is: we would like to be able to collect money both before installing the panels,
   * and after installing them.
   *
   * We'll add the events later, and I'll show you how to setup a subgraph. It's for frontend's use
   */
});
