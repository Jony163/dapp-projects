// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "forge-std/console.sol";

contract Permit2 is ERC20, EIP712 {
    using ECDSA for bytes32;

    // mapping(address => uint256) public nonces;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) EIP712(name, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        // address signer = ecrecover(digest, v, r, s);
        address signer = ECDSA.recover(digest, v, r, s);
        console.log("msg.sender : %s", msg.sender);
        console.log("signer : %s", signer);
        console.log("owner %s", owner);
        require(signer == owner, "Permit: invalid signature");

        _approve(owner, spender, value);
    }
}
