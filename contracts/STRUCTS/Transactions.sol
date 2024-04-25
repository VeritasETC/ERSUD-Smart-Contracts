// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface TransactionDetail{

    enum TransactionType {Deposited, Generated, Withdraw, Repaid, APYWithdraw, FeeCollected}

    struct Transactions{
        uint256 createdAt;
        uint256 amount;
        TransactionType transctionType;
    }
}
