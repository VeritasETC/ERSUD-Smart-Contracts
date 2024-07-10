// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./TransactionEnums.sol";
interface TransactionDetail is TransactionEnums{

    struct Transactions{
        uint256 createdAt;
        uint256 amount;
        TransactionType transctionType;
    }
}
