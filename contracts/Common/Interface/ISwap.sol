// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwap
{
    function swap(address _erusdToken, address _destination, uint256 _amount) external returns(uint256 cost, uint256 acquire);
}