// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/ISolar.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SolarPanelTime is ISolar { 

    address public owner; 
    uint ROIRate = 10;

    constructor() {
        owner = msg.sender;
    }

    struct Investor { 
        address investmentToken;
        uint balance;
        uint initialInvestmentTime;
        uint availableWithdrawalBalance;
        uint withdrawedAmount;
    }

    mapping (address => Investor) investors;


    function deposit(address token, uint investmentAmount) public payable {
        IERC20(token).transferFrom(msg.sender, address(this), investmentAmount);
        investors[msg.sender].initialInvestmentTime = block.timestamp;
        investors[msg.sender].balance = investmentAmount;
        investors[msg.sender].availableWithdrawalBalance = 0;
        investors[msg.sender].withdrawedAmount = 0;
        console.log("deposit token from msg.sender address to the contract's address");
        

    }

    function getTotalProfitTime() public view returns(uint) {
        uint currentTransactionTime = block.timestamp;
        uint timeSpan = (currentTransactionTime - investors[msg.sender].initialInvestmentTime);
        console.log("get total profit timespan between first investment and current investment");
        return timeSpan;
    }

    function getTotalProfit() public view returns(uint) {
        uint timeSpan = getTotalProfitTime();
        uint totalProfit = ROIRate * timeSpan * investors[msg.sender].balance;
        console.log("get total profit since the initial investment");
        return totalProfit;
    }

    function getAvailableWithdrawal() public view returns(uint) {
        uint totalProfit = getTotalProfit();
        uint availableWithdrawalBalance = (totalProfit - investors[msg.sender].withdrawedAmount);
        console.log("get difference between total profit and withdrawed amount");
        return availableWithdrawalBalance;
    }

    function balanceOfInvestor() public view returns(uint) {
        console.log("get balance of investor");
        return investors[msg.sender].balance;
    }
        
    function getWithdrawedAmount() public view returns(uint) {
        uint withdrawed = investors[msg.sender].withdrawedAmount;
        console.log("get total withdrawed amount since the initial investment");
        return withdrawed;
    }


  
    function withdraw() public payable {
        uint availableAmount = getAvailableWithdrawal();
        // investors[msg.sender].availableWithdrawalBalance = availableAmount;
        investors[msg.sender].withdrawedAmount = investors[msg.sender].withdrawedAmount + availableAmount;
        IERC20(investors[msg.sender].investmentToken).transfer(msg.sender, availableAmount);
        console.log("withdraw function");
    }

 


    // function totalWithdrawalAmountCalculation() public view returns(uint) {
    //     uint totalProfitTime = totalProfitTimeCalculation();
    //     uint totalProfitAmount = (totalProfitTime * ROIRate * investors[msg.sender].balance);
    //     return totalProfitAmount;
    //  }

    // function availableWithdrawalAmountCalculation() public {
    //     uint totalProfit = totalWithdrawalAmountCalculation();
    //     uint availableWithdrawalAmount = totalProfit - investors[msg.sender].withdrawedAmount;
    //     investors[msg.sender].availableProfit = availableWithdrawalAmount;

    // }

    // function withdraw(uint amount) public payable {
    //     availableWithdrawalAmountCalculation();
    // //require gerekli
    //     IERC20(investors[msg.sender].investmentToken).transfer(msg.sender, amount);
    //     investors[msg.sender].availableProfit -= amount;
    //     investors[msg.sender].withdrawedAmount += amount;

    // }

    // function balanceOfInvestor() public view returns(uint) {
    //     return investors[msg.sender].balance;
    // }

    // function availableProfitQ() public returns(uint) {
    //     uint totalProfit = totalWithdrawalAmountCalculation();
    //     uint availableWithdrawalAmount = totalProfit - investors[msg.sender].withdrawedAmount;
    //     investors[msg.sender].availableProfit = availableWithdrawalAmount;
    //     return investors[msg.sender].availableProfit;
    // }

}

