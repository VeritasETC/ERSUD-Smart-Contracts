// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAPYMapper {
    function addAPYDetails(address _contractAddress, uint256 _apyAmount) external;
    function isAPYExists(address _apyMapperAddress) external view returns (bool);
    function getLatestAPYContract() external view returns(address _latest);
    function getAPYContracts() external view returns (address[] memory);
}