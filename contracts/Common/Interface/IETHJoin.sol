// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IETHJoin {
    function join(address userAddress, uint256 amount, uint256 feeAmount) external ;
    function exit(address userAddress, uint256 amount, uint256 _APYAmout) external;
    function withdrawFee(address _destination, uint256 _amount) external;
    function withdrawAPYAmount(address _userAddress, uint256 _amount) external;
    function sendUserCollateral(address _userAddress, address _destination, uint256 _amount) external;
}