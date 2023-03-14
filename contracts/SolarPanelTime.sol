// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.15;

// import "./interfaces/ISolar.sol";
// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract SolarPanelTime is ISolar { 

//     address public owner; 
//     uint ROIRate = 10;

//     constructor() {
//         owner = msg.sender;
//     }

//     struct Investor { 
//         address investmentToken;
//         uint balance;
//         uint initialInvestmentTime;
//         uint availableWithdrawalBalance;
//         uint withdrawedAmount;
//     }

//     mapping (address => Investor) investors;


//     function deposit(address token, uint investmentAmount) public payable {
//         IERC20(token).transferFrom(msg.sender, address(this), investmentAmount);
//         investors[msg.sender].initialInvestmentTime = block.timestamp;
//         investors[msg.sender].balance = investmentAmount;
//         investors[msg.sender].availableWithdrawalBalance;
//         investors[msg.sender].withdrawedAmount;
//         console.log("deposit token from msg.sender address to the contract's address");
        

//     }

//     function getTotalProfitTime() public view returns(uint) {
//         uint currentTransactionTime = block.timestamp;
//         uint timeSpan = (currentTransactionTime - investors[msg.sender].initialInvestmentTime);
//         console.log("get total profit timespan between first investment and current investment");
//         return timeSpan;
//     }

//     function getTotalProfit() public view returns(uint) {
//         uint timeSpan = getTotalProfitTime();
//         uint totalProfit = ROIRate * timeSpan * investors[msg.sender].balance;
//         console.log("get total profit since the initial investment");
//         return totalProfit;
//     }

//     function getAvailableWithdrawal() public view returns(uint) {
//         uint totalProfit = getTotalProfit();
//         uint availableWithdrawalBalance = (totalProfit - investors[msg.sender].withdrawedAmount);
//         console.log("get difference between total profit and withdrawed amount");
//         return availableWithdrawalBalance;
//     }

//     function balanceOfInvestor() public view returns(uint) {
//         console.log("get balance of investor");
//         return investors[msg.sender].balance;
//     }
        
//     function getWithdrawedAmount(address investorAccount) public view returns(uint) {
//         uint withdrawed = investors[investorAccount].withdrawedAmount;
//         console.log("get total withdrawed amount since the initial investment");
//         return withdrawed;
//     }

//     function increaseWithdrawedAmount(uint amount) public {
//         investors[msg.sender].withdrawedAmount = amount + investors[msg.sender].withdrawedAmount;
//         console.log("increases withdrawed amount");
//     }

  
//     function withdraw(address token, uint amount) public payable {

//         // uint availableAmount = getAvailableWithdrawal();
//         investors[msg.sender].availableWithdrawalBalance = amount;
//         // IERC20(investors[msg.sender].investmentToken).transfer(msg.sender, availableAmount);
//         increaseWithdrawedAmount(amount);
//         IERC20(token).transfer(msg.sender, amount);
//         console.log("withdraw function");
//     }

 


//     // function totalWithdrawalAmountCalculation() public view returns(uint) {
//     //     uint totalProfitTime = totalProfitTimeCalculation();
//     //     uint totalProfitAmount = (totalProfitTime * ROIRate * investors[msg.sender].balance);
//     //     return totalProfitAmount;
//     //  }

//     // function availableWithdrawalAmountCalculation() public {
//     //     uint totalProfit = totalWithdrawalAmountCalculation();
//     //     uint availableWithdrawalAmount = totalProfit - investors[msg.sender].withdrawedAmount;
//     //     investors[msg.sender].availableProfit = availableWithdrawalAmount;

//     // }

//     // function withdraw(uint amount) public payable {
//     //     availableWithdrawalAmountCalculation();
//     // //require gerekli
//     //     IERC20(investors[msg.sender].investmentToken).transfer(msg.sender, amount);
//     //     investors[msg.sender].availableProfit -= amount;
//     //     investors[msg.sender].withdrawedAmount += amount;

//     // }

//     // function balanceOfInvestor() public view returns(uint) {
//     //     return investors[msg.sender].balance;
//     // }

//     // function availableProfitQ() public returns(uint) {
//     //     uint totalProfit = totalWithdrawalAmountCalculation();
//     //     uint availableWithdrawalAmount = totalProfit - investors[msg.sender].withdrawedAmount;
//     //     investors[msg.sender].availableProfit = availableWithdrawalAmount;
//     //     return investors[msg.sender].availableProfit;
//     // }

// }

// ---------------------------------------------------------
    // function calculateProfit(uint projectID) public view returns (uint) {
    //     console.log("zaman fonk", block.timestamp);
    //     uint secondHalfProfitCounter = 0;
    //     uint firstHalfProfitCounter = 0;

    //     for (uint i = 0; i < investors[msg.sender].investments[projectID].length; i++) {
    //         uint investment = investors[msg.sender].investments[projectID][i].amount;
    //         uint timestamp = investors[msg.sender].investments[projectID][i].timestamp;
    //         uint withdrawTime = block.timestamp - timestamp;
    //         uint secsInAYear = 31535000;
    //         uint projectDuration = 20;
    //         uint projectHalfLife = (projectDuration / 2) * secsInAYear;
    //         if (withdrawTime > projectHalfLife) {
    //             uint yUst = ((withdrawTime - projectHalfLife) * (9 * investment)) + (investment * projectHalfLife);
    //             uint yAlt = 10 * secsInAYear * projectHalfLife;
    //             uint result = ((investment * projectHalfLife) / (10 * secsInAYear)) +
    //                 ((yUst * secsInAYear * 10 + investment * yAlt) * (withdrawTime - projectHalfLife)) /
    //                 (20 * secsInAYear * yAlt);
    //             secondHalfProfitCounter += result;
    //             console.log("result2", result);
    //         } else if (withdrawTime <= projectHalfLife) {
    //             uint profitNumerator = investment * withdrawTime;
    //             uint profitDenominator = 10 * secsInAYear;
    //             uint result = profitNumerator / profitDenominator;
    //             firstHalfProfitCounter += result;
    //             console.log("result1", result);
    //         }
    //     }

    //     uint netProfit = firstHalfProfitCounter + secondHalfProfitCounter;
    //     return netProfit;
    // }