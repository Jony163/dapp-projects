// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenBank {
    IERC20 public token; // 关联的 ERC20 Token 合约
    mapping (address => uint256) public balances;

    constructor(address _tokenaddress){
        require(_tokenaddress != address(0), unicode"地址不能为0");
        token = IERC20(_tokenaddress);
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 amount) external virtual{
        require(amount > 0, unicode"存款金额需要大于0");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "transfer failed");
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, unicode"提款金额需要大于0");
        require(balances[msg.sender] > 0, unicode"余额不足");
        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "transfer firled");
        emit Withdraw(msg.sender, amount);
    }
}