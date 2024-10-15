// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ITokensReceived{
    function tokensReceived(address from, uint256 amount) external ;
}