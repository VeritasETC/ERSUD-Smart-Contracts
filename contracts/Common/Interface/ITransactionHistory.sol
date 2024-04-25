// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../STRUCTS/Transactions.sol";

interface ITransactionHistory is TransactionDetail {
    function addTransactions(address _userAddress, Transactions memory _trans) external;
}