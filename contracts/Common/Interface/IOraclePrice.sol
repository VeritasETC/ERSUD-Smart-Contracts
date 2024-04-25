// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOraclePrice{
    function getAmount(uint256 amount) external view returns(uint256);
}