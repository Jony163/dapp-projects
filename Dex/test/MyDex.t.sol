// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../src/MyDex.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is Test, ERC20 {
    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, 1_000_000_000 * 10 ** 6);
    }
}

contract MyDexTest is Test {
    MyDex public dex;
    MockUSDT public usdt;
    address public user;

    uint256 constant ETH_LIQUIDITY = 150 ether;
    uint256 constant USDT_LIQUIDITY = 150_000 * 10 ** 6;
    uint256 constant USER_ETH = 500 ether;
    uint256 constant USER_USDT = 10_000 * 10 ** 6;  

    function setUp() public {
        usdt = new MockUSDT();
        dex = new MyDex(address(usdt));
        user = makeAddr("user");

        // 给DEX打款ETH
        vm.deal(address(dex), ETH_LIQUIDITY);
        // 给DEX打款USDT
        usdt.transfer(address(dex), USDT_LIQUIDITY);

        // 给用户打款
        vm.deal(user, USER_ETH);
        // 给用户打款USDT
        usdt.transfer(user, USER_USDT);

    }

    // 测试卖出ETH换取USDT
    function testSellETH() public {
        // 初始用户ETH余额
        uint256 initUserETH = user.balance;
        // 初始用户USDT余额
        uint256 initUserUSDT = usdt.balanceOf(user);
        // 卖出ETH数量
        uint256 sellAmount = 1 ether;
        // 预期换取的USDT数量
        uint256 expectedUSDT = 1000;
        vm.startPrank(user);
        // 卖出ETH换取USDT
        dex.sellETH{value: sellAmount}(address(usdt), expectedUSDT);
        
        assertEq(user.balance, initUserETH - sellAmount, "ETH balance not as expected");

        assertEq(usdt.balanceOf(user), initUserUSDT + expectedUSDT, "USDT balance not as expected");

        vm.stopPrank();
    }

    // 测试买入ETH换取USDT
    function testBuyETH() public {
        // 初始用户ETH余额
        uint256 initUserETH = user.balance;
        // 初始用户USDT余额
        uint256 initUserUSDT = usdt.balanceOf(user);
        uint256 spendUSDT = 100000;
        uint256 expectedETH = 1 ether;

        vm.startPrank(user);
        // 用户授权DEX使用USDT  
        usdt.approve(address(dex), spendUSDT);
        // 用户买入ETH
        dex.buyETH(address(usdt), spendUSDT, expectedETH);

        assertEq(user.balance, initUserETH + expectedETH, "ETH balance not as expected");
        assertEq(usdt.balanceOf(user), initUserUSDT - spendUSDT, "USDT balance not as expected");

        vm.stopPrank();
    }
}