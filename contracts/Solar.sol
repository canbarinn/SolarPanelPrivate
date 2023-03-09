// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Solar {
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
        uint256 returnOfInvestment; // yearly
        uint256 start; // project start timestamp
        uint256 end; // project end timestamp
        uint256 capacity; // project capacity in dollar amount with 6 decimals
        uint256 totalInvestorAmount; //CAN: This name should be changed.
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
        uint256 returnOfInvestment,
        uint256 start,
        uint256 end,
        uint256 capacity,
        uint256 maxInvestmentsPerInvestor
    ) public onlyOwner {
        //CAN:transaction sonucunu veren bir fonksiyonun returnle kullanılmasına gerek olmadığını gördüm
        projectIdCounter += 1;
        uint256 projectID = projectIdCounter;
        projects[projectID].returnOfInvestment = returnOfInvestment;
        projects[projectID].start = start;
        projects[projectID].end = end;
        projects[projectID].capacity = capacity;
        projects[projectID]
            .maxInvestmentsPerInvestor = maxInvestmentsPerInvestor;

        emit ProjectCreated(projectID);

        console.log("new project created");
        // let's use openzeppelin counter to determine project IDs
        // we should calculate the total profit to be distributed and get it from creator
        // otherwise we shouldn't let them create the project bc how are we gonna now that they'll bring money later on?
    }

    function invest(uint256 projectID, uint256 amount) public {
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "Insufficient balance!"
        );

        require(
            projectID <= projectIdCounter,
            "The project with this ID is non-existent!"
        );
        require(getRemainingCapacity(projectID) >= amount, "Capacity is full!");
        require(
            projects[projectID].maxInvestmentsPerInvestor >= amount,
            "You should invest less amount!"
        );
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        projects[projectID].investors.push(msg.sender);
        investors[msg.sender].investments[projectID].push(
            Investment(block.timestamp, amount)
        );
        investors[msg.sender].investedProjects.push(projectID);
        console.log("investment processed");
    }

    function withdrawProfit(uint256 projectID) public {
        // let's give all the profits for all investments for projectID
    }

    function withdrawProfit() public {
        // let's give all the profits for all investments for all projects
        // this function should loop through each projectID and calculateProfit(), and then aggregate
    }

    function calculateProfit(uint256 projectID) public view returns (uint256) {
        // investor can invest multiple times, thus this function should loop through each investment with the projectID
        // and then aggregate the results

        //i indexindeki döngü çalışacak, her bir investmentİnformation uzunluğu kadaar index dönerek
        //amount ve blocktimestamp değerleri üzreinden tek tek döngü yapacak.
  

        uint256 profitCounter = 0;


        for(uint256 i=0; i < investors[msg.sender].investments[projectID].length; i++) {
            uint invested = investors[msg.sender].investments[projectID][i].amount; 
            uint latestTimestamp = investors[msg.sender].investments[projectID][i].latestTimestamp;
            uint timePassed = block.timestamp - latestTimestamp;
            uint result = calculationTester(invested, timePassed);
            profitCounter += result;
            return profitCounter;
    } }

    function calculationTester(uint invested, uint withdrawTime) public view returns(uint) {
    
        //isimleri düzenle ve first half second half diye iki tane tarafta ayrı ayrı toparla fonksiyonları
        uint investment = invested;
        uint secsInAYear = 31535000;
        uint projectHalfLife = 10 * secsInAYear;
        uint withdrawTime = 15 * secsInAYear; //burası açık olursa hesap tam tutuyor, kapalı olursa zamanda sıkıntı oluyor. Bunu testte çalışmak lazım.

        uint yUst = ((withdrawTime-projectHalfLife)*(9*investment)) + (investment*projectHalfLife);
        uint yAlt = 10 * secsInAYear * projectHalfLife;
        console.log(yUst, yAlt);
        console.log(yUst/yAlt);
        uint result = ((yUst * secsInAYear * 10 + investment * yAlt) * (withdrawTime - projectHalfLife)) / (20 * secsInAYear * yAlt);
        //result = (((yustu* secs_year *10)+(investment*yalt))*(withdrawTime-projectHalfLife))/(20*secs_year*yalt)
        return result + investment; 



    }

    


    function getRemainingCapacity(
        uint256 projectID
    ) public view returns (uint256) {
        return
            projects[projectID].capacity -
            projects[projectID].totalInvestorAmount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    //For Testing Purposes------------------
    function balanceOfInvestor(
        address investor,
        uint256 projectID
    ) public view returns (uint) {
        return investors[investor].investments[projectID][0].amount;
    }

    function getInvestmentTime(
        address investor,
        uint256 projectID
    ) public view returns (uint) {
        return investors[investor].investments[projectID][0].latestTimestamp;
    }
    //For Testing Purposes------------------
}
