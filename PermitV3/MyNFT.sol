// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
这是 ERC721 NFT 合约，用于生成 NFT 资产
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721{
    uint256 public nextTokenId;

    constructor() ERC721("Jony", "JNFT"){}

    function mint(address to) external{
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
    
}