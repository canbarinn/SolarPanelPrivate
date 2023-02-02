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
  });
  describe("Owner actions", () => {
    it("only owner can create projects", async () => {});
    it("project IDs increment sequentially", async () => {});
  });
  describe("Investor actions", () => {
    it("investor can't invest more than their balance", async () => {
      const projectID = await createProject();
      await expect(
        await solar.invest(projectID, dollars("100000"))
      ).to.be.revertedWith("Insufficient balance!");
    });
    it("investor can't invest non-existing project", async () => {});
    it("investor can only invest before end time", async () => {});
    it("investor can't invest if capacity is full", async () => {});
    it("investor can't invest more than 'maxInvestmentsPerInvestor'", async () => {});
  });
  describe("Calculation", () => {
    it("profit calculation is correct for single project profit withdrawal", async () => {});
    it("profit calculation is correct for batch projects profit withdrawal", async () => {});
  });

  /**
   * Side note: we can set the end time for projects 15 years after than start date
   * Business logic is: we would like to be able to collect money both before installing the panels,
   * and after installing them.
   *
   * We'll add the events later, and I'll show you how to setup a subgraph. It's for frontend's use
   */
});
