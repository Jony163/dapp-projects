// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MyToken.sol";

contract NFTMarket {
    using ECDSA for bytes32;

    MyToken public token;
    ERC721 public nft;
    address public admin;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    constructor(MyToken _token, ERC721 _nft) {
        token = _token;
        nft = _nft;
        admin = msg.sender;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing({seller: msg.sender, price: price});
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not for sale");

        require(token.transferFrom(msg.sender, listing.seller, listing.price), "Token transfer failed");
        nft.transferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];
    }

    function permitBuy(
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
                msg.sender,
                tokenId,
                price,
                deadline
            )
        );

        address digest = ecrecover(structHash, v, r, s);

        // 验证签名是否由管理员签发
        require(digest == admin, "Invalid whitelist signature");

        Listing memory listing = listings[tokenId];
        
        require(token.transferFrom(msg.sender, listing.seller, price), "Token transfer failed");
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];
    }
}
