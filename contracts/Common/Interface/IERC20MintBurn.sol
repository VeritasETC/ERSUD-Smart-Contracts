// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IERC20MintBurn {

    function mint(address _userAddress, uint256 _amount) external ;
    function burn(address _userAddress, uint256 _amount) external ;
    function totalSupply() external view returns(uint256);
}
