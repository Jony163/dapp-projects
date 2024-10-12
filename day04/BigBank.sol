// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Bank.sol";


// BigBank 合约，继承自 Bank，增加存款限制和管理员转移功能
contract BigBank is Bank {
    
    // 构造函数
    constructor() {}

    // 限制存款金额必须大于 0.001 
    modifier miniDeposit() {
        require(msg.value > 0.001 ether, unicode"存款金额必须大于 0.001 Ether");
        _;
    }

    // 管理员转移函数
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), unicode"管理员地址无效");
        owner = newOwner;
    }

    // 存款
    function deposit() public payable override miniDeposit{
         require(msg.value > 0, unicode"必须大于0");
        balances[msg.sender] += msg.value;
    }
}