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
        uint256 firstHalfProfitTotal; // total profit to be distributed for all capacity in the first half
    }
    struct Investor {
        uint256[] investedProjects; // ID list of invested projects
        mapping(uint256 => Investment[]) investments; // projectID => Investment
    }
    struct Investment {
        uint256 timestamp; // last time a withdrawal has been done. used for saving the initial investment timestamp
        uint256 amount; // amount of investment in tokens
        uint256 profitGiven; // total profit paid to the investor
    }

    function createProject(
        uint256 APR,
        uint256 start,
        uint256 duration,
        uint256 capacity,
        uint256 maxInvestmentsPerInvestor
    ) public onlyOwner {
        // console.log("start: ", start);
        // console.log("duration: ", duration);
        //CAN:transaction sonucunu veren bir fonksiyonun returnle kullanılmasına gerek olmadığını gördüm
        projectIdCounter += 1;
        uint256 projectID = projectIdCounter;
        projects[projectID].APR = APR;
        projects[projectID].start = start;
        projects[projectID].duration = duration;
        projects[projectID].capacity = capacity;
        projects[projectID].maxInvestmentsPerInvestor = maxInvestmentsPerInvestor;
        projects[projectID].firstHalfProfitTotal =
            (capacity * duration * APR) /
            (2 * SECONDS_IN_A_YEAR * APR_DENOMINATOR);

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
        require(projects[projectID].maxInvestmentsPerInvestor >= amount, "You should invest less amount!");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        projects[projectID].investors.push(msg.sender);
        investors[msg.sender].investments[projectID].push(Investment(block.timestamp, amount, 0));
        investors[msg.sender].investedProjects.push(projectID);
        console.log("investment processed");
    }

    function withdrawSingleProjectProfit(uint256 projectID) public {
        // let's give all the profits for all investments for projectID
        uint totalProfit = calculateProfitDeniz(projectID);
        // console.log("TOTAL profitt: ", totalProfit);

        IERC20(token).transfer(msg.sender, totalProfit);
        // accountun para hesabına bak
        // profit given should be incremented
    }

    function withdrawProfit() public returns (uint allProfitCounter) {
        // let's give all the profits for all investments for all projects
        // this function should loop through each projectID and calculateProfit(), and then aggregate

        for (uint projectID = 1; projectID <= projectIdCounter; projectID++) {
            uint profitHolder = calculateProfit(projectID);
            allProfitCounter += profitHolder;
        }
        console.log(allProfitCounter);

        IERC20(token).transfer(msg.sender, allProfitCounter);
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

    //For Testing Purposes------------------

    function calculateProfit(uint projectID) public view returns (uint) {
        console.log("zaman fonk", block.timestamp);
        uint secondHalfProfitCounter = 0;
        uint firstHalfProfitCounter = 0;

        for (uint i = 0; i < investors[msg.sender].investments[projectID].length; i++) {
            uint investment = investors[msg.sender].investments[projectID][i].amount;
            uint timestamp = investors[msg.sender].investments[projectID][i].timestamp;
            uint withdrawTime = block.timestamp - timestamp;
            uint secsInAYear = 31535000;
            uint projectDuration = 20;
            uint projectHalfLife = (projectDuration / 2) * secsInAYear;
            if (withdrawTime > projectHalfLife) {
                uint yUst = ((withdrawTime - projectHalfLife) * (9 * investment)) + (investment * projectHalfLife);
                uint yAlt = 10 * secsInAYear * projectHalfLife;
                uint result = ((investment * projectHalfLife) / (10 * secsInAYear)) +
                    ((yUst * secsInAYear * 10 + investment * yAlt) * (withdrawTime - projectHalfLife)) /
                    (20 * secsInAYear * yAlt);
                secondHalfProfitCounter += result;
                console.log("result2", result);
            } else if (withdrawTime <= projectHalfLife) {
                uint profitNumerator = investment * withdrawTime;
                uint profitDenominator = 10 * secsInAYear;
                uint result = profitNumerator / profitDenominator;
                firstHalfProfitCounter += result;
                console.log("result1", result);
            }
        }

        uint netProfit = firstHalfProfitCounter + secondHalfProfitCounter;
        return netProfit;
    }

    function calculateProfitDeniz(uint256 projectID) public view returns (uint256 profit) {
        for (uint i = 0; i < investors[msg.sender].investments[projectID].length; i++) {
            uint256 profitGiven = investors[msg.sender].investments[projectID][i].profitGiven;
            uint256 investmentAmount = investors[msg.sender].investments[projectID][i].amount;

            uint256 start = projects[projectID].start;
            uint256 duration = projects[projectID].duration;

            profit +=
                calculateFirstHalfProfit(projectID, investmentAmount, start, duration) +
                calculateLastHalfProfit(projectID, investmentAmount, start, duration) -
                profitGiven;

            //this should be inside withdraw // investors[msg.sender].investments[projectID][i].profitGiven += profit;
        }
    }

    function calculateFirstHalfProfit(
        uint256 projectID,
        uint256 investmentAmount,
        uint256 start,
        uint256 duration
    ) public view returns (uint256 profit) {
        uint256 halfTimestamp = start + (duration / 2);

        uint256 totalProfit = (projects[projectID].firstHalfProfitTotal * investmentAmount) /
            projects[projectID].capacity;

        profit = block.timestamp > halfTimestamp
            ? totalProfit
            : (totalProfit * (block.timestamp - start)) / (duration / 2);

        // if (block.timestamp > halfTimestamp) {
        //     profit = totalProfit;
        // } else {
        //     profit = (totalProfit * (block.timestamp - start)) / (duration / 2);
        // }

        console.log("first PROFIT: ", profit);
    }

    function calculateLastHalfProfit(
        uint256 projectID,
        uint256 investmentAmount,
        uint256 start,
        uint256 duration
    ) public view returns (uint256 profit) {
        uint256 halfTimestamp = start + (duration / 2);

        if (block.timestamp < halfTimestamp) {
            return 0;
        } else {
            uint256 elapsedTimeInSeconds = block.timestamp - halfTimestamp; // elapsed time after half-time

            uint256 totalProfit = (projects[projectID].firstHalfProfitTotal * investmentAmount) /
                (projects[projectID].capacity * 2);

            profit = (totalProfit * elapsedTimeInSeconds * 2) / duration;
            // this should be changed in to yamuk hesabi

            console.log("last PROFIT: ", profit);
        }
    }
}
