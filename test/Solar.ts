import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MockToken, SolarPanel } from "../typechain-types";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Solar", function () {
  let owner: SignerWithAddress;
  let accounts: SignerWithAddress[];

  let solar: SolarPanel;
  let token: MockToken;
  beforeEach(async () => {
    [owner, ...accounts] = await ethers.getSigners();

    const solarFactory = await ethers.getContractFactory("SolarPanel");
    solar = (await solarFactory.deploy()) as SolarPanel;

    const tokenFactory = await ethers.getContractFactory("MockToken");
    token = (await tokenFactory.deploy("MockToken", "Mock")) as MockToken;

    await token.mint(owner.address, "99999999999999999999");
    await token.mint(accounts[0].address, "99999999999999999999");
  });
  it("Deposit", async function () {
    const depositAmount = 1000;

    await token.approve(solar.address, depositAmount); // solar panel'e benim yerime para harcayabilmesi icin approve veriyorum
    await solar.deposit(token.address, depositAmount, owner.address); // bu fonksiyonun icinde solar panel benim yerime parami transfer ediyor.
    // peki neden ona izin vermek yerine kendim gondermiyorum parami?
    // cunku direkt gonderirsem solar kontrati icinde benim balance'imi artiran veya herhangi bir islem yapan kod nasil calisacak?
    // deposit fonksiyonunun icinde parayi aliyor ki devaminda istedigi logic'i calistirabilsin

    console.log(await solar.balanceOfInvestor(owner.address));
    expect(await solar.balanceOfInvestor(owner.address)).eq(depositAmount);
  });
  it("Profit calculation is correct", async () => {
    /**
     * 1-Invest
     * 2-Roll the time forward
     * 3-Withdraw profit
     * 4-Check if profit is correct
     */

    const depositAmount = 1000;
    const profitAmount = 123123123123; // change this

    const balanceBefore = await token.balanceOf(accounts[0].address);

    await token.connect(accounts[0]).approve(solar.address, depositAmount);
    await solar
      .connect(accounts[0])
      .deposit(token.address, depositAmount, accounts[0].address);

    await time.increase(60 * 60 * 24 * 30);

    await solar
      .connect(accounts[0])
      .withdrawFromSolarPanel(accounts[0].address);

    const balanceAfter = await token.balanceOf(accounts[0].address);

    expect(balanceAfter.sub(balanceBefore)).eq(profitAmount);
  });
  /**
   *
   * deposit ederken kendi adina etmeli sadece
   *
   * deposit ve addinvestor fonksiyonlari birlesmeli
   *
   *
   */
});
