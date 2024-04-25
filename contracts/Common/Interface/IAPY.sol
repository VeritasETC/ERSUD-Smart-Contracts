// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAPY{
    function deposit(address _userAddress, uint256 _userAmount, uint256 _amount) external ;
    function calculate(address _userAddress) external view returns(uint256 _APYAmount, uint256 _day);
    function userAPYWithdraw(address _userAddress) external view returns(uint256 _withdrawAmount);
    function setUserAPYWithdraw(address _userAddress, uint256 _amount) external;
    function resetAPYReward(address _userAddress, uint256 _amount) external;
    
}