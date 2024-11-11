// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

contract VaultLogic {

  address public owner;
  bytes32 private password;

  constructor(bytes32 _password){
    owner = msg.sender;
    password = _password;
  }

  function changeOwner(bytes32 _password, address newOwner) public {
    console.logBytes32(_password);
    console.logBytes32(password);
    if (password == _password) {
        owner = newOwner;
    } else {
      revert("password error");
    }
  }
}

contract Vault {

  address public owner;
  VaultLogic logic;
  mapping (address => uint) deposites;
  bool public canWithdraw = false;

  constructor(address _logicAddress){
    logic = VaultLogic(_logicAddress);
    owner = msg.sender;
  }

  // Vault 合约中并没有 changeOwner 函数
  // 所以当调用 changeOwner 时，会触发 fallback
  // msg.data 包含了完整的调用数据：
  // 1. 函数选择器（4字节）：changeOwner 函数的签名哈希
  // 2. 参数数据：编码后的 bytes32 _password 和 address newOwner
  /**
    攻击合约 
    -> call(changeOwner) 
    -> Vault合约 
    -> 找不到changeOwner函数 
    -> 触发fallback 
    -> delegatecall到VaultLogic 
    -> 执行changeOwner
  */
  fallback() external {
    (bool result,) = address(logic).delegatecall(msg.data);
    if (result) {
      this;
    }
  }

  receive() external payable {

  }

  function deposite() public payable { 
    deposites[msg.sender] += msg.value;
  }

  function isSolve() external view returns (bool){
    if (address(this).balance == 0) {
      return true;
    } 
    return false;
  }

  function openWithdraw() external {
    if (owner == msg.sender) {
      canWithdraw = true;
    } else {
      revert("not owner");
    }
  }

  function withdraw() public {
    // 存在重入攻击风险 应该遵循 checks-effects-interactions 模式
    console.log(canWithdraw);
    console.log(deposites[msg.sender]);
    if(canWithdraw && deposites[msg.sender] >= 0) {
      (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
      if(result) {
        // 应该在转账之前更新状态
        deposites[msg.sender] = 0;
      }
      
    }

  }
  

}
