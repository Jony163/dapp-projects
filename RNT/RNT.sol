// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RNT is ERC20 {
    constructor() ERC20("JoRNT", "JoRNT"){
        _mint(msg.sender, 100000 ether);
    }
}