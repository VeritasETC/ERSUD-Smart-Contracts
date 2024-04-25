// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERUSDJoin {
    function join(address userAddress, uint256 amount) external ;
    function claim(address userAddress) external;
    function exit(address userAddress, uint256 amount) external ;
}