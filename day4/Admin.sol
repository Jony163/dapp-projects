// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBank.sol";

// Admin 合约，拥有自己的 Owner，并支持从 IBank 合约中提取资金
contract Admin {
    address public adminOwner;

    // 构造函数
    constructor() {
        adminOwner = msg.sender;
    }

    // 只有 Owner 才能调用
    modifier onlyAdminOwner() {
        require(msg.sender == adminOwner, unicode"只有 Admin Owner 可以调用此功能");
        _;
    }

    // 提款
    function adminWithdraw(IBank bank) public onlyAdminOwner {
        IBank(bank).withdraw();
    }

    // 获取合约余额
    function getbalance() public view returns (uint256) {
        return address(this).balance;
    }

    //接收转账
    receive() external payable {}
}