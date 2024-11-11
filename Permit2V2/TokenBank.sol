// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/permit2/src/interfaces/IPermit2.sol";

/**
主要优势：
用户只需要进行一次交易就能完成存款，而不是传统的先 approve 再 deposit 两次交易
更好的用户体验，因为签名操作是即时的，不需要等待区块确认
可以节省 gas 费用
 */


contract TokenBank {
    IERC20 public token;
    IPermit2 public constant PERMIT2 = IPermit2(0x000000000022d47303072EAB70B5b49C845BC774);

    mapping(address => uint256) public balances;

    constructor(address _token) {
        token = IERC20(_token);
    }



    function deposit(uint256 amount) external{
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external{
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function depositWithPermit2(
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external{
        // 合约接收到签名后，构建相同的permit结构
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({
                token : address(token),  //代币地址
                amount : amount
            }),
            nonce : 0,             //与签名时nonce一致
            deadline : deadline  //与签名时deadline一致
        });

        // 创建转移详情 
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),    //接收方（TokenBank合约）
            requestedAmount: amount
        });

        // 执行转移
        PERMIT2.permitTransferFrom(
            permit,
            transferDetails,
            msg.sender,    //签名者
            signature   //用户签名
        );

        balances[msg.sender] += amount;
    }



}
