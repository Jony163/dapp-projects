// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";
interface Dex {
    function sellETH(address buyToken, uint256 minBuyAmount) external payable;
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external;
}

contract MyDex is Dex{

    address public usdtAddress;
    uint256 constant RATE = 1500;

    constructor(address _usdtAddress) {
        usdtAddress = _usdtAddress;
    }

    modifier onlyUSDT(address token) {
        require(token == usdtAddress, "Only USDT is allowed");
        _;
    }

    // 卖出ETH换取USTD
    function sellETH(address buyToken, uint256 minBuyAmount) external payable override onlyUSDT(buyToken) {
        require(msg.value > 0, "ETH amount must be greater than 0");
        uint256 usdtAmount = (msg.value * RATE) / 1e18;
        console.log("======msg.value", msg.value * RATE);
        console.log("======msg.value", msg.value);
        console.log("======usdtAmount", usdtAmount);
        console.log("======minBuyAmount", minBuyAmount);
        require(usdtAmount >= minBuyAmount, "Insufficient USDT amount received");
        // 将USTD转给调用者
        IERC20(buyToken).transfer(msg.sender, usdtAmount);
    }

    // 卖出USTD换取ETH
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external override onlyUSDT(sellToken) {
        require(sellAmount > 0, "Amount must be greater than 0");

        uint256 ethAmount = sellAmount * 1e18 / RATE;
        console.log("======ethAmount", ethAmount);
        console.log("======minBuyAmount", minBuyAmount);
        require(ethAmount >= minBuyAmount, "Insufficient ETH amount received");
        require(address(this).balance >= ethAmount, "Not enough ETH in the contract");

        // 将USTD转给合约
        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);
        // 将ETH转给调用者
        (bool success,) =msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {}
}

