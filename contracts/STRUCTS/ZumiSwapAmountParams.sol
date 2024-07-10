// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ZumiSwapAmountParams{
    struct SwapAmountParams {
        bytes path;
        address recipient;
        uint128 amount;
        uint256 minAcquired;
        uint256 deadline;
    }
}