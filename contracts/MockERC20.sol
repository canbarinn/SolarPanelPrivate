// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

/**
 * @title   The contract to create ERC20 MockToken  
 */

contract MockToken is ERC20 {
    // solhint-disable-next-line
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice  Mints token
     * @param   account  The address of the account to which tokens will be minted
     * @param   amount  The number of tokens to be minted
     */
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    /**
     * @notice  Burns token
     * @param   account  The address of the account from which tokens will be burned
     * @param   amount  The number of tokens to be burned
     */
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
