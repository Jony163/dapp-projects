// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TokenBank.sol";

contract TokenBankV2 is TokenBank{

    address public tokenAddress;

    constructor(address _tokenAddress) TokenBank(_tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) public override {
        require(amount > 0, "Amount must be greater than zero");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        balances[msg.sender] += amount;
    }

    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(IERC20(token).transferWithCallback(msg.sender, amount), "transferWithCallback failed");
    }
}