// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Solar {
    address public owner;
    address public token;

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

    struct Project {
        uint256 ROI; // yearly
        uint256 start; // project start timestamp
        uint256 end; // project end timestamp
        uint256 capacity; // project capacity in dollar amount with 6 decimals
        uint256 totalInvestment;
        uint256 maxInvestmentsPerInvestor; // # of investments a single investor can make to the project
        address[] investors; // address list of investors
    }
    struct Investor {
        uint256[] investedProjects; // ID list of invested projects
        mapping(uint256 => Investment[]) investments; // projectID => Investment
    }
    struct Investment {
        uint256 latestTimestamp; // last time a withdrawal has been done. used for saving the initial investment timestamp
        uint256 amount; // amount of investment in tokens
    }

    function createProject(
        uint256 ROI,
        uint256 start,
        uint256 end,
        uint256 capacity,
        uint256 maxInvestmentsPerInvestor
    ) public onlyOwner returns (uint256) {
        // let's use openzeppelin counter to determine project IDs
        // we should calculate the total profit to be distributed and get it from creator
        // otherwise we shouldn't let them create the project bc how are we gonna now that they'll bring money later on?
    }

    function invest(uint256 projectID, uint256 amount) public {
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "Insufficient balance!"
        );
    }

    function withdrawProfit(uint256 projectID) public {
        // let's give all the profits for all investments for projectID
    }

    function withdrawProfit() public {
        // let's give all the profits for all investments for all projects
        // this function should loop through each projectID and calculateProfit(), and then aggregate
    }

    function calculateProfit(uint256 projectID) public {
        // investor can invest multiple times, thus this function should loop through each investment with the projectID
        // and then aggregate the results
    }

    function getRemainingCapacity(uint256 projectID)
        public
        view
        returns (uint256)
    {
        return
            projects[projectID].capacity - projects[projectID].totalInvestment;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}
