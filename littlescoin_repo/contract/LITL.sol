// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
   LittlesCoin (LITL)
   Reference BEP20 Token Contract for Documentation & CoinMarketCap Listing
   This contract is a clean, auditable reference implementation.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LittlesCoin is ERC20, Ownable {

    uint8 private _decimals = 9;

    constructor() ERC20("LittlesCoin", "LITL") Ownable(msg.sender) {
        // Initial supply (example): 1,000,000 tokens (adjust if needed)
        uint256 initialSupply = 1_000_000 * 10 ** _decimals;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
