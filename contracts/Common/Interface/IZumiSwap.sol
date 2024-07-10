// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../STRUCTS/ZumiSwapAmountParams.sol";

interface IZumiSwap is ZumiSwapAmountParams{
    function swapAmount(SwapAmountParams calldata params) external payable returns (uint256 cost, uint256 acquire) ;
    function WETH9() external view returns(address);
}