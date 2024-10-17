// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NFTMarker{
    //ERC20 Token 合约
    IERC20 public tokenContract;
    IERC721 public nftContract;

    //市场上的NFT结构
    struct Listing {
        address seller;
        uint256 price; 
    }

    //存储NFT上架信息 NFT合约地址 => TokenID => Listing
    mapping(uint256 => Listing) public listings;

    //事件定义
    event NFTListed(uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTPurchased(uint256 indexed tokenId, uint256 price, address indexed buyer);

    constructor(address _nftContract, address _tokenContract){
        nftContract = IERC721(_nftContract);
        tokenContract = IERC20(_tokenContract);
    }


    //list() : NFT 持有者可以上架nft, 设置价格
    function list(uint256 tokenId, uint256 price) external{
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        require(price > 0, "Price must be greater than 0");

        //将 NFT 上架
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        // 将 NFT 转移到市场合约中
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(tokenId, price, msg.sender);
    }

    // tokensReceived 方法中购买 nft
    function tokensReceiverd(address buyer, uint256 amount, uint256 tokenId) public{
        Listing memory listing = listings[tokenId];
        require(amount == listing.price, "Incorrect token amount");

        //从买家转移到买家
        require(tokenContract.transferFrom(buyer, listing.seller, listing.price), "Token transfer failed");

        //从NFT市场转移到买家
        nftContract.transferFrom(address(this), buyer, tokenId);

        //清除上架信息
        delete listings[tokenId];
        
        emit NFTPurchased(tokenId, listing.price, buyer);
    }

    //购买功能
    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed for sale");

        // 通过 扩展的 tokensReceived 方法进行购买
        tokensReceiverd(msg.sender, listing.price, tokenId);

    }
}

contract MyToken is ERC20{
    constructor() ERC20("Jony", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // 铸造 100 万个 Token
    }

    // tokensReceived 实现，用于触发 NFT 购买逻辑
    function tokensReceived(address nftaddress, uint256 tokenId) external {
        // Token 接收逻辑由 NFTMarket 合约完成
        NFTMarker nft = NFTMarker(nftaddress);
        nft.buyNFT(tokenId);
    }
}