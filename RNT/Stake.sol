// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
编写一个完整的质押挖矿合约，实现如下功能：
1，用户随时可以质押项目方代币 RNT(自定义的ERC20) ，开始赚取项目方Token(esRNT)；
2，可随时解押提取已质押的 RNT；
3，可随时领取esRNT奖励，每质押1个RNT每天可奖励 1 esRNT;
4，esRNT 是锁仓性的 RNT， 1 esRNT 在 30 天后可兑换 1 RNT，随时间线性释放，
支持提前将 esRNT 兑换成 RNT，但锁定部分将被 burn 燃烧掉。
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard{
    IERC20 public immutable rntToken;   //项目方代币
    IERC20 public immutable esRntToken;  //项目方奖励代币
    uint256 public constant rewardRate = 1;  //每天每质押1个RNT奖励1个 esRNT
    uint256 public constant lockTime = 30 days;  //esRNT 线性释放时间
    uint256 public earlyWithdrawFeeRate = 10;  //提前提取手续费

    struct StakeInfo {
        uint256 amount;     //  质押的RNT数量
        uint256 rewardDebt;   //已经领取的奖励
        uint256 lastStakedTime;  //上次质押时间
        uint256 unlockTime;     //释放时间
    }
    
    mapping(address => StakeInfo) public stakes;  //用户质押信息

    // 事件定义
    event Pledge(address indexed user, uint256 amount, uint256 unlockTime);
    event Unpledge(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event RewardUpdated(uint256 newRate);

    constructor(IERC20 _rntToken, IERC20 _esRntToken) Ownable(msg.sender){
        rntToken = _rntToken;
        esRntToken = _esRntToken;
    }

    //质押
    function pledge(uint256 _amount, uint256 _lockTime) external nonReentrant{
        require(_amount > 0, "Amount must be greater than zero");

        StakeInfo storage userStake = stakes[msg.sender];

        //更新奖励信息
        _updateRewards(msg.sender);

        //转移rnt到合约
        require(rntToken.transferFrom(msg.sender, address(this), _amount), "Transfer feiled");

        userStake.amount += _amount;
        userStake.lastStakedTime = block.timestamp;
        userStake.unlockTime = block.timestamp + _lockTime;
        
        emit Pledge(msg.sender, _amount, _lockTime);
    }

    //解除质押，提取已质押的RNT
    function unpledge(uint256 _amount) external nonReentrant{

        StakeInfo storage userStake = stakes[msg.sender];

        //确保用户有足够的质押数量
        require(_amount > 0 && _amount <= userStake.amount, "Insufficient staked amount");

        uint256 fee = 0;
        if (block.timestamp < userStake.unlockTime){
            fee = _amount * earlyWithdrawFeeRate / 100;   //计算手续费
        }

        //更新奖励信息
        _updateRewards(msg.sender);

        // 减少用户的质押数量
        userStake.amount -= _amount;

        //将RNT从合约转给用户
        require(rntToken.transfer(msg.sender, _amount - fee), "Transfer failed");

        if (fee > 0){
            require(rntToken.transfer(owner(), fee), "Fee transfer failed");
        }

        emit Unpledge(msg.sender, _amount);
    }

    // 用户领取esRNT奖励
    function claimRewards() external nonReentrant{

        _updateRewards(msg.sender);

        StakeInfo storage userStake = stakes[msg.sender];

        //确保用户有奖励可领取
        require(userStake.rewardDebt > 0, "NO rewards to claim");

        //获取esRNT奖励
        uint256 reward = userStake.rewardDebt;

        //将esRNT奖励清零并设置解锁开始时间
        userStake.rewardDebt = 0;
        userStake.unlockTime = block.timestamp;

        //将esRNT转移给用户
        require(esRntToken.transfer(msg.sender, reward), "Transfer failed");

        emit Claimed(msg.sender, reward);
    }

    //用户提前将esRNT转换为RNT, 未释放的锁仓部分将被销毁（燃烧）
    function convertEsRntToRnt(uint256 _esAmount) external {

        StakeInfo storage userStake = stakes[msg.sender];

        //检查用户的esRNT余额是否足够
        require(userStake.rewardDebt >= _esAmount, "Insufficient esRNT balance");

        //计算锁仓解锁的时间
        uint256 elapsed = block.timestamp - userStake.unlockTime;

        //计算可以提取的RNT数量，按线性释放计算
        uint256 availableRnt = (_esAmount * elapsed) / lockTime;

        //减少用户的esRNT余额
        userStake.amount -= _esAmount;

        if(availableRnt > 0){
            //提取相比例的RNT
            require(rntToken.transfer(msg.sender, availableRnt), "Transfer failed");
        }

        //销毁锁仓未到期的部分 esRNT
        uint256 burnAmount = _esAmount - availableRnt;
        if (burnAmount > 0){
            require(esRntToken.transfer(address(0), burnAmount), "Burn failed");
        }
    }


    //更新奖励
    function _updateRewards(address _user) internal{

        StakeInfo storage userStake = stakes[_user];

        if (userStake.lastStakedTime > 0){

            //  计算自上次领取后经过的时间
            uint256 elapsedTime = block.timestamp - userStake.lastStakedTime;

            //根据时间计算应发放的奖励
            uint256 reward = (userStake.amount * rewardRate * elapsedTime) / 1 days;

            // 累计用户的esRNT奖励
            userStake.rewardDebt += reward;

            emit RewardUpdated(reward);
        }

         userStake.lastStakedTime = block.timestamp;
    }

    //查看用户可领取的奖励（查看函数）
    function pendingReward(address _user) external view returns (uint256){
        StakeInfo storage userStake = stakes[_user];

        //计算从上次领取奖励到当前的时间
        uint256 elapsedTime = block.timestamp - userStake.lastStakedTime;

        //计算奖励
        uint256 reward = (userStake.amount * rewardRate * elapsedTime) / 1 days;

        //返回当前累计的奖励
        return userStake.rewardDebt + reward;
    }
}

