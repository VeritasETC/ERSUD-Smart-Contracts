// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVault{
    function can(address fromAddress, address toAddress) external view returns(bool);
    function lock(address usr, uint256 amount, uint256 fee) external;
    function draw(address usr, uint256 amount) external;
    function move(address src, address dst, uint256 rad) external;
    function ERUSD(address userAddress) external view returns(uint256);
    function eth(address userAddress) external view returns(uint256);
    function updateERUSD(address _userAddress, uint256 _amount) external ;
    function suck(address usr, uint256 amount, uint8) external;
    function slip(address usr, uint256 amount, uint8) external;
    function setTotalFeeCollected(uint256 _amount) external;
    function updateTotalFeeCollected(uint256 _amount) external;
    function totalfeeCollected() external view returns(uint256);
    function setTotalAPYSent(uint256 _amount) external;
    function minCollateralRatio() external view returns(uint256);
    function withdrawAPYAmount(address _userAddress, uint256 _amount) external;
    function setInitialRatio(address usr, uint256 ratio) external ;
    function initialRatio() external view returns(uint256);
    function setUserInitialUSDTAmount(address usr, uint256 usdtAmount) external;
    function userUSDTAmount(address user) external view returns(uint256);
    function totalCollatral() external view returns (uint256);
    function debt() external view returns (uint256);
    function userDepositTime(address _userAddress) external view returns(uint256);
    function lastRewardTime(address _userAddress) external view returns (uint256);
    function setLastRewardTime(address _userAddress, uint256 _time) external ;
    function setAuthenticUser(address usr) external;
    function setAPYContract(address _APYContract) external;
    function isLoaner(address _userAddress) external view returns(bool);
}
