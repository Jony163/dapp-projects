// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
实现⼀个可升级的工厂合约，工厂合约有两个方法：

deployInscription(string symbol, uint totalSupply, uint perMint) ，
该方法用来创建 ERC20 token，（模拟铭文的 deploy）， symbol 表示 Token 的名称，
totalSupply 表示可发行的数量，perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量

mintInscription(address tokenAddr) 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
 */

 contract InscriptionToken is Initializable, ERC20Upgradeable{

    uint256 public perMint;

    function initialize(string memory symbol, uint256 totalSupply, uint256 _perMint) public initializer{
        __ERC20_init("JMK", symbol);
        _mint(msg.sender, totalSupply);
        perMint = _perMint;
    }

    function mint(address to) public {
        require(perMint > 0, "perMint not set");
        _mint(to, perMint);
    }
 }

 contract InscriptionFactory{

    address public implementation;
    mapping(address => address) public ownerToToken;

    event TokenDeployed(address indexed owner, address tokenAddress);

    constructor(address _implementation){
        implementation = _implementation;
    }

    function deloyInscription(string memory symbol, uint256 totalSupply, uint256 perMint) external{
        require(ownerToToken[msg.sender] == address(0), "Token aleady deployed");
        //使用clone工厂合约部署新实例
        address clone = Clones.clone(implementation);
        InscriptionToken(clone).initialize(symbol, totalSupply, perMint);

        //记录部署的Token地址
        ownerToToken[msg.sender] = clone;

        emit TokenDeployed(msg.sender, clone);
    }

    function mintInscription(address tokenAddr) external {
        require(ownerToToken[msg.sender] == tokenAddr,"Unauthorized");

        //调用Token的mint功能
        InscriptionToken(tokenAddr).mint(msg.sender);
    }

 }