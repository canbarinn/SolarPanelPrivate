// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Solar {
    uint256 SECONDS_IN_A_YEAR = 31536000;
    uint256 APR_DENOMINATOR = 100;

    address public owner;
    address public token;
    uint projectIdCounter;

    mapping(uint256 => Project) projects; // projectID => Project
    mapping(address => Investor) investors; // investor address => Investor

    constructor(address _token) {
        owner = msg.sender;
        token = _token;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner!");
        _;
    }

    event ProjectCreated(uint projectID);

    struct Project {
        uint256 APR; // if $10,000 dolar investment return $1,500 after a year, it's 15%. for precision, it should be 1500.
        uint256 start; // project start timestamp
        uint256 duration; // project duration timestamp
        uint256 capacity; // project capacity in dollar amount with 6 decimals
        uint256 totalInvestorAmount; //CAN: This name should be changed.
        uint256 maxInvestmentsPerInvestor; // # of investments a single investor can make to the project
        address[] investors; // address list of investors
    }
    struct Investor {
        uint256[] investedProjects; // ID list of invested projects
        mapping(uint256 => Investment[]) investments; // projectID => Investment
        uint256 profitGiven;
    }
    struct Investment {
        uint256 timestamp; // last time a withdrawal has been done. used for saving the initial investment timestamp
        uint256 amount; // amount of investment in tokens
        uint256 firstHalfTotalProfit;
        uint256 potentialTotalProfit;
    }

    function createProject(
        uint256 APR,
        uint256 start,
        uint256 duration,
        uint256 capacity,
        uint256 maxInvestmentsPerInvestor
    ) public onlyOwner {
        projectIdCounter += 1;
        uint256 projectID = projectIdCounter;
        projects[projectID].APR = APR;
        projects[projectID].start = start;
        projects[projectID].duration = duration;
        projects[projectID].capacity = capacity;
        projects[projectID].maxInvestmentsPerInvestor = maxInvestmentsPerInvestor;

        emit ProjectCreated(projectID);

        console.log("new project created with ID: ", projectID);
        // let's use openzeppelin counter to determine project IDs
        // we should calculate the total profit to be distributed and get it from creator
        // otherwise we shouldn't let them create the project bc how are we gonna now that they'll bring money later on?
    }

    function invest(uint256 projectID, uint256 amount) public {
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient balance!");

        require(projectID <= projectIdCounter, "The project with this ID is non-existent!");
        require(getRemainingCapacity(projectID) >= amount, "Capacity is full!");
        require(
            projects[projectID].maxInvestmentsPerInvestor >= investors[msg.sender].investments[projectID].length,
            "You can't invest!"
        );
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        projects[projectID].investors.push(msg.sender);
        investors[msg.sender].investedProjects.push(projectID);
        console.log("investment processed");
        uint256 firstHalfTotalProfit = (amount * projects[projectID].APR * (projects[projectID].duration / 2)) /
            (SECONDS_IN_A_YEAR * APR_DENOMINATOR);
        uint256 potentialTotalProfit = (firstHalfTotalProfit * 3) / 2;
        //console.log("first half:",firstHalfTotalProfit, "total:", potentialTotalProfit);
        investors[msg.sender].investments[projectID].push(
            Investment(block.timestamp, amount, firstHalfTotalProfit, potentialTotalProfit)
        );
    }

    function withdrawSingleProjectProfit(uint256 projectID) public {
        // // let's give all the profits for all investments for projectID
        // uint totalProfit = calculateProfit(projectID);
        // // console.log("TOTAL profitt: ", totalProfit);
        // IERC20(token).transfer(msg.sender, totalProfit);
    }

    function withdrawProfit() public returns (uint allProfitCounter) {
        // // let's give all the profits for all investments for all projects
        // // this function should loop through each projectID and calculateProfit(), and then aggregate
        // for (uint projectID = 1; projectID <= projectIdCounter; projectID++) {
        //     uint profitHolder = calculateProfit(projectID);
        //     allProfitCounter += profitHolder;
        // }
        // console.log(allProfitCounter);
        // IERC20(token).transfer(msg.sender, allProfitCounter);
    }

    function getRemainingCapacity(uint256 projectID) public view returns (uint256) {
        return projects[projectID].capacity - projects[projectID].totalInvestorAmount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    //For Testing Purposes------------------
    function balanceOfInvestor(address investor, uint256 projectID) public view returns (uint) {
        return investors[investor].investments[projectID][0].amount;
    }

    function getInvestmentTime(address investor, uint256 projectID) public view returns (uint) {
        return investors[investor].investments[projectID][0].timestamp;
    }

    function getInvestmentCount(address investor, uint256 projectID) public view returns (uint) {
        return investors[investor].investments[projectID].length;
    }

    function calculateProfitCan(uint256 projectID) public view returns (uint) {
        uint256 profitCounterLast;
        uint256 profitCounterFirst;

        for (uint256 index = 0; index < investors[msg.sender].investments[projectID].length; index++) {
            uint256 halfTimestamp = investors[msg.sender].investments[projectID][index].timestamp +
                (projects[projectID].duration / 2);
            console.log(halfTimestamp);

            if (block.timestamp > halfTimestamp) {
                uint256 elapsedTimeInSeconds = block.timestamp - halfTimestamp;
                console.log(elapsedTimeInSeconds);
                profitCounterLast += calculateTotalProfitCanBA(projectID, elapsedTimeInSeconds, index);
                console.log("prof", profitCounterLast);
            } else {
                uint256 timePassed = block.timestamp - investors[msg.sender].investments[projectID][index].timestamp;
                profitCounterFirst += calculateFirstHalfProfitCanBA(projectID, timePassed, index);
            }
            console.log("profitCounterinfor", profitCounterLast);
            console.log("profitCounterinfor", profitCounterFirst);
        }
        console.log("profitCounteroutfor", profitCounterLast);
        console.log("profitCounteroutfor", profitCounterFirst);
        return profitCounterLast + profitCounterFirst;
    }

    function calculateTotalProfitCanBA(
        uint256 projectID,
        uint256 elapsedTimeInSeconds,
        uint256 index
    ) public view returns (uint) {
        uint256 remainingProfitRate = ((((projects[projectID].duration - (2 * elapsedTimeInSeconds)) ** 2) *
            projects[projectID].APR) / (4 * projects[projectID].duration * SECONDS_IN_A_YEAR));
        console.log("profit rate remaining:", remainingProfitRate);
        uint256 remainingProfit = (remainingProfitRate * investors[msg.sender].investments[projectID][index].amount) /
            APR_DENOMINATOR;
        console.log("remaining profit", remainingProfit);
        uint256 netProfit = investors[msg.sender].investments[projectID][index].potentialTotalProfit - remainingProfit;
        console.log("net profit", netProfit);
        console.log("net profit", netProfit);
        return netProfit;
    }

    function calculateFirstHalfProfitCanBA(
        uint256 projectID,
        uint256 timePassed,
        uint256 index
    ) public view returns (uint) {
        // elapsed time after half-time

        uint256 netProfit = (investors[msg.sender].investments[projectID][index].amount *
            projects[projectID].APR *
            (timePassed)) / (SECONDS_IN_A_YEAR * APR_DENOMINATOR);
        return netProfit;
    }
}
