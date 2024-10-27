// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
扩展 ERC20 合约 ，添加一个有hook 功能的转账函数，如函数名为：transferWithCallback ，
在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external;
}

contract MyERC20WithCallback is ERC20{
    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    //扩展的转账函数，支持合约调用
    function transferWithCallback(address to, uint256 amount) public returns (bool){
        _transfer(_msgSender(), to, amount);
    

        //检查目标地址是否为合约
        if (isContract(to)){
            ITokenReceiver(to).tokensReceived(_msgSender(), amount);  //调用合约的tokensReceived方法
        }
        return true;
    }

    //判断地址是否为合约
    function isContract(address addr) internal view returns (bool){
        uint32 size;
        assembly{
            size := extcodesize(addr)
        }
        return (size > 0);
    }





}

