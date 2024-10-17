// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义 IBank 接口
interface IBank {
    function withdraw() external ;
    function getbalance() external view returns (uint256);
    function deposit() external payable ;
}