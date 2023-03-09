// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.9;

// import "./interfaces/ISolar.sol";
// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// /* 
// @title
// @notice
// @dev
// */
// contract SolarPanel is ISolar {
//     uint128 roiPercentage;
//     address public owner;

//     constructor() {
//         owner = msg.sender;
//     }

//     struct Investor {
//         address payable walletAddress;
//         string name;
//         bool active;
//         uint256 balance; //her solar panel aktif hale getirildiginde ucreti kadar token transfer edilmeli
//         uint256 investmentBalance;
//         uint256 start;
//         uint256 end;
//     }

//     mapping(address => Investor) public investors;

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     //investor eklerken default value veremiyorum buradaki variablelari tek tek elle girmek gerekiyor
//     function addInvestor(
//         address payable walletAddress,
//         string memory name,
//         bool active,
//         uint256 balance,
//         uint256 investmentBalance,
//         uint256 start,
//         uint256 end
//     ) public {
//         investors[walletAddress] = Investor(
//             walletAddress,
//             name,
//             active,
//             balance,
//             investmentBalance,
//             start,
//             end
//         );
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     function deposit(
//         address token,
//         uint256 amount,
//         address walletAddress
//     ) public payable {
//         // IERC20(token).approve(walletAddress, amount);
//         IERC20(token).transferFrom(msg.sender, address(this), amount);
//         investors[walletAddress].balance += amount;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     /*
//     burada transferFrom kullanmama sebebimiz zaten fonksiyon calisirken 
//     otomatik olarak bu addressten gonderilecegi icin mi 

//     evet :)
//     */
//     function withdraw(
//         address token,
//         uint256 amount,
//         address walletAddress
//     ) public payable {
//         IERC20(token).transfer(msg.sender, amount);
//         investors[walletAddress].balance -= amount;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     function balanceOf() public view returns (uint256) {
//         return address(this).balance;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     function balanceOfInvestor(address walletAddress)
//         public
//         view
//         returns (uint256)
//     {
//         require(
//             walletAddress == msg.sender || owner == msg.sender,
//             "You are not allowed to see the balance of this account."
//         );
//         return investors[walletAddress].balance;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     // bu fonksiyonu sadece kontratin owneri cagirabilecek
//     function setRoiPercentage(uint128 percentage) public {
//         roiPercentage = percentage;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     //bunlar aslinda sadece tokenlarla degil de basit sayilarla yapildigi icin aslinda payable olmasa da olur mu?
//     function investToSolarPanel(address walletAddress, uint256 investmentAmount)
//         public
//         payable
//     {
//         investors[walletAddress].balance -= investmentAmount;
//         investors[walletAddress].investmentBalance += investmentAmount;
//         investors[walletAddress].active = true;
//         investors[walletAddress].start = block.timestamp;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */
//     function totalInvestmentDuration(uint256 start, uint256 end)
//         internal
//         pure
//         returns (uint256)
//     {
//         return end - start;
//     }

//     /*
//     @notice
//     @dev
//     @param
//     @return
//     */

//     function investmentDurationInMinutes(address walletAddress)
//         public
//         view
//         returns (uint256)
//     {
//         uint256 timeSpan = totalInvestmentDuration(
//             investors[walletAddress].start,
//             investors[walletAddress].end
//         );
//         uint256 timespanInMinutes = timeSpan / 60;
//         return timespanInMinutes;
//     }

//     function calculateNetReturnOfInvestment(address walletAddress)
//         public
//         view
//         returns (uint256)
//     {
//         require(
//             walletAddress == msg.sender || owner == msg.sender,
//             "You are not allowed to calculate return of investment of this account."
//         );
//         require(
//             investors[walletAddress].investmentBalance > 0,
//             "You have 0 return of investment."
//         );

//         uint256 investmentDuration = investmentDurationInMinutes(walletAddress);
//         uint256 returnOfInvestmentPerMinute = ((
//             investors[walletAddress].investmentBalance
//         ) * roiPercentage) / 52596000;
//         uint256 netReturnOfInvestment = (returnOfInvestmentPerMinute *
//             investmentDuration) + investors[walletAddress].investmentBalance;
//         return netReturnOfInvestment;
//     }

//     function withdrawFromSolarPanel(address walletAddress) public payable {
//         require(
//             walletAddress == msg.sender || owner == msg.sender,
//             "You are not allowed to withdraw from this account."
//         );
//         require(
//             investors[walletAddress].active = true,
//             "You have no active Solar Panel investment."
//         );
//         require(
//             investors[walletAddress].investmentBalance > 0,
//             "Your balance is empty."
//         );
//         investors[walletAddress].end = block.timestamp;
//         //burada hesaplanan paranin geri verilmesi gerekiyor
//         uint256 withdrawalAmount = calculateNetReturnOfInvestment(
//             walletAddress
//         );
//         investors[walletAddress].investmentBalance = 0;
//         investors[walletAddress].balance += withdrawalAmount;
//         investors[walletAddress].start = 0;
//         investors[walletAddress].end = 0;
//         investors[walletAddress].active = false;
//     }
// }
