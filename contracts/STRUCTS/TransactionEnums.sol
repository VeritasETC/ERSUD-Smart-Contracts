// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface TransactionEnums{
    enum TransactionType {Deposited, Generated, Withdraw, Repaid, APYWithdraw, FeeCollected, RepaidByLiquidity, collateralLiquidate}
}
