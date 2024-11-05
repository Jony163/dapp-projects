// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract esRNT is ERC20 {
    constructor () ERC20("JoesRNT", "JoesRNT"){
        _mint(msg.sender, 100000 ether);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}