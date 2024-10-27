// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenBank.sol";
import "./MyERC20WithCallback.sol";

/**
继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，用户可以直接调用 
transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。
 */
 
contract TokenBankV2 is TokenBank, ITokenReceiver{
    address public acceptedToken;

    constructor(address _acceptedToken){
        acceptedToken = _acceptedToken;
    }

    //实现tokensReceived 记录存款
    function tokensReceived(address from, uint256 amount) external override{
        require(msg.sender == acceptedToken, "Invalid token");
        balances[from] += amount;   //记录用户的存款
    }
}