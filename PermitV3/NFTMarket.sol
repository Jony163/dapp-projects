// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MyToken.sol";
import "./MyNFT.sol";

contract NFTMarket {
    using ECDSA for bytes32;

    MyToken public token;
    MyNFT public nft;
    address public admin;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    constructor(MyToken _token, MyNFT _nft) {
        token = _token;
        nft = _nft;
        admin = msg.sender;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing({seller: msg.sender, price: price});
    }

    function buyNFT(uint256 tokenId) public {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not for sale");

        require(token.transferFrom(msg.sender, listing.seller, listing.price), "Token transfer failed");
        nft.transferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];
    }

    function permitBuy(
        address buyer,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(listings[tokenId].price == price, "Invalid price");
        require(block.timestamp <= deadline, "Signature expired");

        // 构建用于验证白名单的结构哈希
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address buyer,uint256 tokenId,uint256 price,uint256 deadline)"),
                buyer,
                tokenId,
                price,
                deadline
            )
        ); 

        address signer = ECDSA.recover(structHash, v, r, s);

        // 从签名和消息计算 signer，并验证签名
        require(signer == admin, "Invalid whitelist signature");

        buyNFT(tokenId);
    }
}
