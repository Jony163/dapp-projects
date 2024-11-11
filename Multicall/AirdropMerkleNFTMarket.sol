// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "./Mytoken.sol";
import "./MyNFT.sol";

/**
实现一个 AirdopMerkleNFTMarket 合约
(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架（和之前的上架逻辑一致）
指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

permitPrePay() : 调用token的 permit 进行授权
claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，
转入 token 转出 NFT 。
 */

contract AirdropMerkleNFTMarket {
    MyToken public token; // 代币
    MyNFT public nft; // nft
    bytes32 public merkleRoot; // 默克尔树根

    mapping(address => bool) public hashClaimed; // 是否领取
    mapping(uint256 => uint256) public nftPrices; // nft价格
    constructor(address _token, address _nft, bytes32 _merkleRoot) {
        token = MyToken(_token);
        nft = MyNFT(_nft);
        merkleRoot = _merkleRoot;
    }

    // 上架 nft
    function listNFT(uint256 tokenId, uint256 price, bytes32[] calldata merkleProof) external {
        // 验证白名单   
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not in whitelist");
        // 检查 nft 是否存在
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        // 检查 nft 是否被批准  
        require(nft.getApproved(tokenId) == address(this), "Not approved");
        nftPrices[tokenId] = price;
    }

    // 授权
    function permitPrePay(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    // 领取 nft 
    function claimNFT(
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external {
        // 检查是否领取
        require(!hashClaimed[msg.sender], "Already claimed");
        // 检查 nft 是否存在
        require(nftPrices[tokenId] > 0, "NFT not listed");
        // 验证默克尔树
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not in whitelist");
        // 50% 折扣
        uint256 discountedPrice = nftPrices[tokenId] / 2;
        // 转入 token
        require(IERC20(address(token)).transferFrom(msg.sender, address(this), discountedPrice), "Transfer failed");
        // 转出 nft
        nft.transferFrom(nft.ownerOf(tokenId), msg.sender, tokenId);
        // 标记已领取
        hashClaimed[msg.sender] = true;
        // 清空价格
        nftPrices[tokenId] = 0;
    }

    // 多重调用
    /**
        可以将 permitPrePay() 和 claimNFT() 的调用数据编码后放入一个数组
        通过一次 multicall 调用同时执行这两个操作
        示例调用顺序：
            第一个调用：执行 token 的 permit 授权
            第二个调用：验证白名单并完成 NFT 购买
    */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        // 初始化结果数组
        results = new bytes[](data.length);
        // 遍历执行每个 call
        for (uint256 i = 0; i < data.length; i++) {
            // 使用 delegatecall 在当前合约的上下文中执行调用
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "Call failed");
            results[i] = result;
        }
    }
}
