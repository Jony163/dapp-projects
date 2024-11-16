// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KKToken is ERC20, Ownable {
    address public stakingPool;

    constructor() ERC20("KK Token", "KK"){
        stakingPool = msg.sender;
    }

    function sertStakingPool(address _stakingPool) external onlyOwner {
        require(_stakingPool != address(0), "Invalid staking pool address");
        stakingPool = _stakingPool;
    }

    function setStakingPool(address _stakingPool) external onlyOwner {
        require(_stakingPool != address(0), "Invalid staking pool address");
        stakingPool = _stakingPool;
    }

    function mint(address to, uint256 amount) external override {
        require(msg.sender == stakingPool, "Only staking pool can mint");
        _mint(to, amount);
    }
    
}
