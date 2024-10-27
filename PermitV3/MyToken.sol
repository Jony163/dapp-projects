// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20Permit {
    constructor() ERC20("Jony", "JNFT") ERC20Permit("Jony") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}