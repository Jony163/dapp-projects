// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
编写 IDO 合约，实现 Token 预售，需要实现如下功能：
1,  开启预售: 支持对给定的任意ERC20开启预售，设定预售价格，募集ETH目标，超募上限，预售时长。
2, 任意用户可支付ETH参与预售；
3, 预售结束后，如果没有达到募集目标，则用户可领会退款；
4,  预售成功，用户可领取 Token，且项目方可提现募集的ETH；
提交要求
     编写 IDO 合约 和对应的测试合约
    foundry test 测试执行结果
 */
 
contract IDO is Ownable {
    IERC20 public saleToken;    // 销售代币
    uint256 public salePrice;   // 销售价格
    uint256 public goal;        // 目标金额
    uint256 public cap;         // 上限金额
    uint256 public endTime;     // 结束时间
    uint256 public totalETHContributed; // 总贡献金额
    bool public isWithdraw;    // 是否可以提现
    
    constructor() Ownable(msg.sender) {}

    mapping(address => uint256) public contributions;  // 贡献金额
    mapping(address => uint256) public tokenClaims;    // 已领取代币数量

    event PresaleStarted(address token, uint256 price, uint256 goal, uint256 cap, uint256 endTime);
    event Contributed(address indexed user, uint256 amountETH);
    event TokenClaimed(address indexed user, uint256 amountToken);
    event Refunded(address indexed user, uint256 amountETH);
    event Withdrawed(uint256 amountETH);

    // 预售中
    modifier onlyDuringSale(){
        require(block.timestamp < endTime, "IDO: Sale has ended");
        _;
    }

    // 结束预售
    modifier onlyAfterSale(){
        require(block.timestamp > endTime, "IDO: Sale is not over");
        _;
    }

    // 启动预售
    function startPresale(
        IERC20 _saleToken,
        uint256 _salePrice,
        uint256 _goal,
        uint256 _cap,
        uint256 _duration
    ) external onlyOwner{
        // 检查参数
        require(address(_saleToken) != address(0), "IDO: Sale token cannot be the zero address");
        // 检查价格
        require(_salePrice > 0, "IDO: Sale price must be greater than 0");
        // 检查目标和上限
        require(_goal > 0, "IDO: Goal must be greater than 0");
        require(_cap >= _goal, "IDO: Cap must be _cap >= _goal");

        saleToken = _saleToken;
        salePrice = _salePrice;
        goal = _goal;
        cap = _cap;
        // 设置结束时间
        endTime = block.timestamp + _duration;
        // 初始化贡献和提现状态
        totalETHContributed = 0;
        isWithdraw = false;

        emit presaleStarted(address(_saleToken), _salePrice, _goal, _cap, endTime);
    }

    // 贡献
    function contribute() external payable onlyDuringSale{
        // 检查贡献金额
        require(msg.value > 0, "IDO: Amount must be greater than 0");
        // 检查上限
        require(totalETHContributed + msg.value <= cap, "IDO: Cap exceeded");
        // 更新贡献金额
        contributions[msg.sender] += msg.value;
        // 更新总贡献金额
        totalETHContributed += msg.value;

        emit Contributed(msg.sender, msg.value);
    }

    // 领取代币
    function claimTokens() external onlyAfterSale{
        // 检查目标
        require(totalETHContributed >= goal, "IDO: Goal not reached");
        // 检查贡献
        require(contributions[msg.sender] > 0, "IDO: No contribution");
        // 计算代币数量
        uint256 tokensToClaim = contributions[msg.sender] / salePrice;
        
        // 转移代币
        saleToken.transfer(msg.sender, tokensToClaim);
        // 更新贡献
        contributions[msg.sender] = 0;

        emit TokenClaimed(msg.sender, tokensToClaim);
    }

    // 退款
    function refund() external onlyAfterSale{
        // 检查目标
        require(totalETHContributed < goal, "IDO: Goal reached");
        // 检查贡献
        uint256 amountETH = contributions[msg.sender];
        require(amountETH > 0, "IDO: No contribution");
        // 更新贡献
        contributions[msg.sender] = 0;
        // 转移ETH
        payable(msg.sender).transfer(amountETH);
        emit Refunded(msg.sender, amountETH);
    }

    // 提现
    function withdraw() external onlyOwner onlyAfterSale{
        // 检查目标
        require(totalETHContributed >= goal, "IDO: Goal not reached");
        // 检查提现状态
        require(!isWithdraw, "IDO: Already withdrawn");
        // 提现
        uint256 amountETH = address(this).balance;
        // 更新提现状态
        isWithdraw = true;
        // 转移ETH
        payable(msg.sender).transfer(amountETH);
        emit Withdrawed(amountETH);
    }
}
