// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct VaultSTRUCT {
    uint256 id;
    uint256 collateralRatio;
    uint256 collateralAmount;
    uint256 erusdAmount;
    uint256 createdAt;
    uint256 updatedAd;
    bool isDeleted;
}