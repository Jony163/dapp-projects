// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank{

    mapping (address => uint256) public balances;

    address public owner;

    //前三名用户
    address[3] public topUsers;
    //前三名用户金额
    uint256[3] public topDep;

    constructor(){
        owner = msg.sender;
    }

    receive() external  payable {
       deposit();
    }

    // 存款
    function deposit() public payable {
         require(msg.value > 0, "Must be greater than 0");
        balances[msg.sender] += msg.value;

        updateTopUsers(msg.sender, balances[msg.sender]);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not administrator");
        _;
    }

    //提取
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "no balance");

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "error");
    }

    //更新
    function updateTopUsers(address user, uint256 dep) internal {
    for (uint256 i = 0; i < 3; i++) {
        if (dep > topDep[i]) {
            for (uint256 j = 2; j > i; j--) {
                topUsers[j] = topUsers[j - 1];
                topDep[j] = topDep[j - 1];
            }
            topUsers[i] = user;
            topDep[i] = dep;
            break;
        }
    }
}

    //获取总余额
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    //获取前3名存储用户的地址和存款金额
    function getTopUsers() public view returns(address[3] memory users, uint256[3] memory dep){
        return (topUsers, topDep);
    }

}