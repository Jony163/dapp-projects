// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KKToken.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}

interface IStaking {
    // 质押
    function stake() payable external;
    // 赎回
    function unstake(uint256 amount) external;
    // 领取奖励
    function claim() external;
    // 获取用户质押的token数量
    function balanceOf(address account) external view returns(uint256);
    // 获取用户应得的奖励
    function earned(address account) external view returns (uint256);
}

contract StakingPool is IStaking, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IToken public immutable token;
    uint256 public constant PRE_BlOCK = 10 ether;

     // 添加一个状态变量来追踪最后的奖励区块
    uint256 public lastRewardBlock;

    struct UserInfo {
        // 用户质押的token数量
        uint256 amount;
        // 用户质押的token对应的奖励
        uint256 rewardDebtl;
        // 用户上次质押的区块高度   
        uint256 lastStakeBlock;
    }

    // 总质押量
   uint256 public totalStaked;
   // 总奖励
   uint256 public accRewardPerShare;
   // 精度
   uint256 private constant ACC_REWARD_PRECISION = 1e12;

   mapping(address => UserInfo) public userInfo;

   event Stake(address indexed user, uint256 amount);
   event Unstake(address indexed user, uint256 amount);
   event Claim(address indexed user, uint256 amount);

   constructor(address _token) {
    lastRewardBlock = block.number;
    require(_token != address(0), "Invalid token address");
    token = IToken(_token);
   }

    // 质押
   function stake() external payable override nonReentrant {
    require(msg.value > 0, "Invalid stake amount");
    // 更新奖励
    updatePool();
    // 获取用户质押信息
    UserInfo storage user = userInfo[msg.sender];
    // 如果用户已经质押，则计算用户应得的奖励
    if (user.amount > 0) {
        // 用户应得的奖励 = 用户质押的token数量 * 总奖励 / 精度 - 用户奖励
        uint256 pending = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION).sub(user.rewardDebt);
        // 如果用户应得的奖励大于0，则发放奖励
        if (pending > 0) {
            token.mint(msg.sender, pending);
        }
    }
    // 更新用户质押信息 用户质押的token数量 = 用户质押的token数量 + 用户质押的token数量
    user.amount = user.amount.add(msg.value);
    // 用户奖励 = 用户质押的token数量 * 总奖励 / 精度
    user.rewardDebtl = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);
    // 更新用户上次质押的区块高度
    user.lastStakeBlock = block.number;
    // 更新总质押量 
    totalStaked = totalStaked.add(msg.value);

    emit Stake(msg.sender, msg.value);

   }

    // 赎回
   function unstake(uint256 amount) external override nonReentrant {
     require(amount > 0, "Invalid unstake amount");
     UserInfo storage user = userInfo[msg.sender];
     require(user.amount >= amount, "Invalid unstake amount");
     
     updatePool();

    // 用户应得的奖励 = 用户质押的token数量 * 总奖励 / 精度 - 用户奖励
     uint256 pending = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION).sub(user.rewardDebt);
     if(pending > 0){
        token.mint(msg.sender, pending);
     }

     user.amount = user.amount.sub(amount);
     // 用户奖励 = 用户质押的token数量 * 总奖励 / 精度
     user.rewardDebt = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);
     // 更新用户上次质押的区块高度
     user.lastStakeBlock = block.number;
     // 更新总质押量
     totalStaked = totalStaked.sub(amount);
     // 赎回token
     (bool success,) = msg.sender.call{value: amount}("");
     require(success, "Transfer failed");

     emit Unstake(msg.sender, amount);
   }

   // 领取奖励
   function claim() external override nonReentrant {

    // 更新池子状态
    updatePool();

    UserInfo storage user = userInfo[msg.sender];
    //用户应得的奖励 = 用户质押的token数量 * 总奖励 / 精度 - 用户奖励
    uint256 pending = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION).sub(user.rewardDebt);

    require(pending > 0, "No pending reward");
    //用户奖励 = 用户质押的token数量 * 总奖励 / 精度
    user.rewardDebt = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);
    // 如何领取奖励的呢？
    token.mint(msg.sender, pending);

    emit Claim(msg.sender, pending);
   }

   // 获取用户质押的token数量
   function balanceOf(address account) external view override returns (uin256){
    return userInfo[account].amount;
   }

   // 获取用户应得的奖励
   function earned(address accnount) external view override returns(uint256){
     UserInfo storage user = userInfo[account];
     // 当前总奖励
     uint256 currentRewardPerShare = accRewardPerShare;
     // 如果总质押量大于0，并且当前区块高度大于用户上次质押的区块高度
     if (totalStaked > 0 && block.number > user.lastStakeBlock){
        // 区块差值 = 当前区块高度 - 用户上次质押的区块高度
        uint256 blocks = block.number.sub(user.lastStakeBlock);
        // 奖励 = 区块差值 * 每个区块的奖励
        uint256 reward = blocks.mul(PRE_BlOCK);
        // 当前总奖励 = 当前总奖励 + 奖励 * 精度 / 总质押量
        currentRewardPerShare = currentRewardPerShare.add(reward.mul(ACC_REWARD_PRECISION).div(totalStaked));
     }
    // 用户应得的奖励 = 用户质押的token数量 * 当前总奖励 / 精度 - 用户奖励
     return user.amount.mul(currentAccRewardPerShare).div(ACC_REWARD_PRECISION).sub(user.rewardDebt);

   }

    // 更新池子状态
   function updatePool() internal {
    if (totalStaked == 0) return;

    uint256 lastBlock = block.number;
    
    // 如果当前区块高度小于等于上次奖励区块高度，则不更新奖励
    if (lastBlock <= lastRewardBlock) return;

    // 计算区块差值 = 当前区块高度 - 上次奖励区块高度
    uint256 blocks = lastBlock.sub(lastRewardBlock);
    // 计算奖励 = 区块差值 * 每个区块的奖励
    uint256 reward = blocks.mul(PRE_BlOCK);
    // 更新总奖励 = 总奖励 + 奖励 * 精度 / 总质押量
    accRewardPerShare = accRewardPerShare.add(reward.mul(ACC_REWARD_PRECISION).div(totalStaked));
    // 更新最后奖励区块
    lastRewardBlock = lastBlock;

   }

}
