// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract MyContract{

    uint public counter;

    //初始化
    constructor() {
        counter = 0;
    }

    function add() public {
        counter = counter + 1;
    }

    function get() public view returns(uint){
        return counter;
    }

}