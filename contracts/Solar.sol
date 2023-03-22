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
    }

    function invest(uint256 projectID, uint256 amount) public {
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient balance!");
        require(projectID <= projectIdCounter, "The project with this ID is non-existent!");
        require(getRemainingCapacity(projectID) >= amount, "Capacity is full!");
        require(
            projects[projectID].maxInvestmentsPerInvestor >= investors[msg.sender].investments[projectID].length,
            "You can't invest!"
        );
        require(block.timestamp - projects[projectID].start < projects[projectID].duration, "Project is no longer available.");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        investors[msg.sender].investedProjects.push(projectID);
        projects[projectID].investors.push(msg.sender);
        uint256 firstHalfTotalProfit = (amount * projects[projectID].APR * (projects[projectID].duration / 2)) /
            (SECONDS_IN_A_YEAR * APR_DENOMINATOR);
        investors[msg.sender].investments[projectID].push(Investment(block.timestamp, amount, firstHalfTotalProfit));
        projects[projectID].totalInvestorAmount += amount;
    }

    function withdrawProfit(uint256 amount) public {
        uint256 availableProfit = getBalance();
        require(availableProfit >= amount, "Unavailable amount!");
        IERC20(token).transfer(msg.sender, amount);
        investors[msg.sender].profitGiven += amount;
    }

    function getBalance() public view returns (uint256 netBalance) {
        uint256 balanceCounter;
        for (uint256 ID = 1; ID <= projectIdCounter; ID++) {
            balanceCounter += calculateProfit(ID);
        }

        netBalance = balanceCounter - investors[msg.sender].profitGiven;
    }

    function calculateProfit(uint256 projectID) public view returns (uint256 netProfit) {
        uint256 profitCounterLast;
        uint256 profitCounterFirst;

        //LASTLYEXPLAIN THIS CALCULATION

        for (uint256 index = 0; index < investors[msg.sender].investments[projectID].length; index++) {
            uint256 halfTimestamp = investors[msg.sender].investments[projectID][index].timestamp +
                (projects[projectID].duration / 2);

            if (block.timestamp > halfTimestamp) {
                uint256 elapsedTimeInSeconds = block.timestamp - halfTimestamp;
                profitCounterLast += calculateTotalProfit(projectID, elapsedTimeInSeconds, index);
            } else {
                uint256 timePassed = block.timestamp - investors[msg.sender].investments[projectID][index].timestamp;
                profitCounterFirst += calculateFirstHalfProfit(projectID, timePassed, index);
            }
        }
        netProfit = profitCounterLast + profitCounterFirst;
    }

    function calculateTotalProfit(
        uint256 projectID,
        uint256 elapsedTimeInSeconds,
        uint256 index
    ) public view returns (uint256 netProfit) {
        uint256 remainingProfitRate = ((((projects[projectID].duration - (2 * elapsedTimeInSeconds)) ** 2) *
            projects[projectID].APR) / (4 * projects[projectID].duration * SECONDS_IN_A_YEAR));
        uint256 remainingProfit = (remainingProfitRate * investors[msg.sender].investments[projectID][index].amount) /
            APR_DENOMINATOR;
        uint256 potentialTotalProfit = (investors[msg.sender].investments[projectID][index].firstHalfTotalProfit * 3) /
            2;
        netProfit = potentialTotalProfit - remainingProfit;
    }

    function calculateFirstHalfProfit(
        uint256 projectID,
        uint256 timePassed,
        uint256 index
    ) public view returns (uint256 netProfit) {
        netProfit =
            (investors[msg.sender].investments[projectID][index].amount * projects[projectID].APR * (timePassed)) /
            (SECONDS_IN_A_YEAR * APR_DENOMINATOR);
    }

    function getRemainingCapacity(uint256 projectID) public view returns (uint256) {
        return projects[projectID].capacity - projects[projectID].totalInvestorAmount;
    }

    function balanceOfInvestor(address investor, uint256 projectID) public view returns (uint256) {
        return investors[investor].investments[projectID][0].amount;
    }
}
