// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint initial supply to deployer for testing
        _mint(msg.sender, 1000000 * 10**18); // 1M tokens with 18 decimals
    }
}