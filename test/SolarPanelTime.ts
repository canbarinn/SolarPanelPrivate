// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { MockToken, SolarPanelTime } from "../typechain-types";
// import { time } from "@nomicfoundation/hardhat-network-helpers";

// describe("Solar", function () {
//   let owner: SignerWithAddress;
//   let accounts: SignerWithAddress[];

//   let solar: SolarPanelTime;
//   let token: MockToken;
//   beforeEach(async () => {
//     [owner, ...accounts] = await ethers.getSigners();

//     const solarFactory = await ethers.getContractFactory("SolarPanelTime");
//     solar = (await solarFactory.deploy()) as SolarPanelTime;

//     const tokenFactory = await ethers.getContractFactory("MockToken");
//     token = (await tokenFactory.deploy("MockToken", "Mock")) as MockToken;

//     await token.mint(owner.address, "99999999999999999999");
//     await token.mint(accounts[0].address, "99999999999999999999");
//   });
//   it("Deposit", async function () {
//     const depositAmount = 1000;

//     await token.approve(solar.address, depositAmount); // solar panel'e benim yerime para harcayabilmesi icin approve veriyorum
//     await solar.deposit(token.address, depositAmount); // bu fonksiyonun icinde solar panel benim yerime parami transfer ediyor.
//     // peki neden ona izin vermek yerine kendim gondermiyorum parami?
//     // cunku direkt gonderirsem solar kontrati icinde benim balance'imi artiran veya herhangi bir islem yapan kod nasil calisacak?
//     // deposit fonksiyonunun icinde parayi aliyor ki devaminda istedigi logic'i calistirabilsin

//     console.log(await solar.balanceOfInvestor());
//     expect(await solar.balanceOfInvestor()).eq(depositAmount);
//   });

// it("Available withdrawal calculation is correct", async () => {

//   const depositAmount = 1000;
//   const defaultTimeDif = 2;
//   await token.approve(solar.address, depositAmount);
//   await solar.deposit(token.address, depositAmount);

//   await token.connect(accounts[0]).approve(solar.address, depositAmount);
//   await solar
//     .connect(accounts[0])
//     .deposit(token.address, depositAmount);

//   await time.increase(60);

//   const profit =  await solar.getAvailableWithdrawal();

//   expect(profit).eq(((60+defaultTimeDif) * 10 * depositAmount));

// });

// it("Withdraw function is working", async () =>  {

//   const depositAmount = 1000;
//   // await token.approve(solar.address, depositAmount);

//   console.log((await token.balanceOf(accounts[0].address)).toString());

//   // await solar.deposit(token.address, depositAmount);

  
//   await token.connect(accounts[0]).approve(solar.address, depositAmount);
//   await solar
//   .connect(accounts[0])
//   .deposit(token.address, depositAmount);
  
//   console.log((await token.balanceOf(accounts[0].address)).toString());
//     await time.increase(60 * 60 * 24 * 365)

//   await solar
//     .connect(accounts[0])
//     .withdraw(token.address, 50);

//     console.log((await token.balanceOf(accounts[0].address)).toString());

//   const withdrawedAmount = await solar.getWithdrawedAmount(accounts[0].address);

//   expect(withdrawedAmount).eq(50);










// })



//   //buradan öncesi son hali 

// //   it("Profit calculation is correct", async () => {

// //     const depositAmount = 1000;
// //     const expectedResult = 90;

// //     await token.approve(solar.address, depositAmount);
// //     await solar.deposit(token.address, depositAmount);

// //     const balanceBefore = await token.balanceOf(accounts[0].address);

// //     await token.connect(accounts[0]).approve(solar.address, depositAmount);
// //     await solar
// //       .connect(accounts[0])
// //       .deposit(token.address, depositAmount);
    
// //     await solar.setROIRate(10);

// //     await time.increase(60 * 60 * 24);

// //     await token.connect(accounts[0]).approve(solar.address, depositAmount);
// //     await solar
// //       .connect(accounts[0])
// //       .withdraw();
    
// //     const balanceAfter = await token.balanceOf(accounts[0].address);

// //     expect(balanceBefore.sub(balanceAfter).eq(expectedResult));

// // });

// //   it("Time calculation is working", async () => {
// //     const depositAmount = 1000;

// //     await token.approve(solar.address, depositAmount);
// //     await solar.deposit(token.address, depositAmount);

// //     await token.connect(accounts[0]).approve(solar.address, depositAmount);
// //     await solar
// //       .connect(accounts[0])
// //       .deposit(token.address, depositAmount)

// //     await time.increase(60 * 60);

// //     let timeSpan = await solar.timeCalculation()

// //     expect(timeSpan).eq(60);






// //   });




//   // it("Profit calculation is correct", async () => {
//   //   /**
//   //    * 1-Invest
//   //    * 2-Roll the time forward
//   //    * 3-Withdraw profit
//   //    * 4-Check if profit is correct
//   //    */

//   //   const depositAmount = 1000;
//   //   const profitAmount = 0; // change this
//   //   await token.approve(solar.address, depositAmount); 
//   //   await solar.deposit(token.address, depositAmount);

//   //   const balanceBefore = await token.balanceOf(accounts[0].address);

//   //   await token.connect(accounts[0]).approve(solar.address, depositAmount);
//   //   await solar
//   //      .connect(accounts[0])
//   //      .deposit(token.address, depositAmount);

//   //   await solar
//   //      .connect(accounts[0])
//   //      .withdraw(1000);

//   //     const balanceAfter = await token.balanceOf(accounts[0].address);

//   //     expect(balanceAfter.sub(balanceBefore)).eq(profitAmount);
//   // });
//   /**
//    *
//    * deposit ederken kendi adina etmeli sadece
//    *
//    * deposit ve addinvestor fonksiyonlari birlesmeli
//    *
//    *
//    */
// });
