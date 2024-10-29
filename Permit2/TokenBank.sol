// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Permit2.sol"; // 导入 Permit2 合约

contract TokenBank {
    using ECDSA for bytes32;

    MyToken public token;

    mapping(address => uint256) public balances;

    constructor(MyToken _token) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(amount);
    }

    function depositWithPermit2(
        uint256 amount,
        address permit2Address,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        Permit2 permit2 = Permit2(permit2Address);
        permit2.permit(owner, address(this), amount, deadline, v, r, s);
        require(token.transferFrom(owner, address(this), amount), "Transfer failed");
        balances[owner] += amount;
    }
}
