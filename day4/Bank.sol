// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBank.sol";

// Bank 合约，实现基础的存款和提款功能
contract Bank is IBank {
    mapping(address => uint256) public balances;
    address public owner;

    // 构造函数，初始化管理员
    constructor() {
        owner = msg.sender;
    }

    // 限制只有管理员才能调用
    modifier onlyOwner() {
        require(msg.sender == owner, unicode"只有管理员可以调用此功能");
        _;
    }

    // 接收存款
    receive() external payable {
        deposit();
    }

    // 提款
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, unicode"合约余额不足");
        payable(owner).transfer(address(this).balance);
    }

    // 获取合约余额
    function getbalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 存款
    function deposit() public virtual  payable {
        require(msg.value > 0, unicode"必须大于0");
        balances[msg.sender] += msg.value;
    }
}