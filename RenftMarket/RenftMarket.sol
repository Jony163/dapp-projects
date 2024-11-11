//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RenftMarket is EIP712 {
    using ECDSA for bytes32;

    event BorrowNFT(address indexed taker, address indexed maker, bytes32 orderHash, uint256 collalteral);
    event OrderCancelled(address indexed maker, bytes32 orderHash);

    mapping(bytes32 => BorrowOrder) public Orders; 
    mapping(bytes32 => bool) public cancelledOrders;

    bytes32 private constant RENTOUT_ORDER_TYPEHASH = keccak256(
        "RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)"
    );

    constructor() EIP712("RentoutMarket", "1") {}

    struct RentoutOrder {
        address maker;   // 出租人
        address nft_ca;  // nft合约地址
        uint256 token_id; // nft id
        uint256 daily_rent; // 每日租金
        uint256 max_rental_duration; // 最大租期
        uint256 min_collateral; // 最低抵押金额
        uint256 list_endtime; // 下架时间
    }

    struct BorrowOrder {
        address taker; // 借用者
        uint256 collateral; // 抵押金额
        uint256 start_time; // 租期开始时间
        RentoutOrder rentinfo; // 出租订单
    }

    // 借用nft
    function borrow(RentoutOrder calldata order, bytes calldata signature) external payable {
        bytes32 orderHash = _hashTypedDataV4(
            keccak256(abi.encode(
                RENTOUT_ORDER_TYPEHASH,
                order.maker,
                order.nft_ca,
                order.token_id,
                order.daily_rent,
                order.max_rental_duration,
                order.min_collateral,
                order.list_endtime
            ))
        );

        // 订单不存在
        require(!cancelledOrders[orderHash], "Order already cancelled");
        // 签名验证
        address signer = orderHash.recover(signature);
        // 签名者必须是出租者
        require(signer == order.maker, "Invalid signature");
        // 订单未过期
        require(block.timestamp < order.list_endtime, "Order expired");
        // 抵押金额不足
        require(msg.value >= order.min_collateral, "Insufficient collateral");

        // 转移nft
        IERC721 nft = IERC721(order.nft_ca);
        nft.transferFrom(order.maker, msg.sender, order.token_id);

        // 记录借用订单
        Orders[orderHash] = BorrowOrder({
            taker: msg.sender,
            collateral: msg.value,
            start_time: block.timestamp,
            rentinfo: order
        });

        emit BorrowNFT(msg.sender, order.maker, orderHash, msg.value);
    }
    
    // 取消订单
    function cancelOrder(RentoutOrder calldata order, bytes calldata signature) external {
        bytes32 orderHash = _hashTypedDataV4(
            keccak256(abi.encode(
                RENTOUT_ORDER_TYPEHASH,
                order.maker,
                order.nft_ca,
                order.token_id,
                order.daily_rent,
                order.max_rental_duration,
                order.min_collateral,
                order.list_endtime
            ))
        );

        // 签名验证
        address signer = orderHash.recover(signature);
        // 签名者必须是出租者
        require(signer == msg.sender, "Invalid signature");
        
        cancelledOrders[orderHash] = true;

        emit OrderCancelled(order.maker, orderHash);
    }

    // 订单信息hash
    function orderInfoHash(RentoutOrder calldata order) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(
                RENTOUT_ORDER_TYPEHASH, 
                order.maker, 
                order.nft_ca, 
                order.token_id, 
                order.daily_rent, 
                order.max_rental_duration, 
                order.min_collateral, 
                order.list_endtime
            ))
        );
    }
}
