// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/ERC20/Ownable.sol";
import "./Common/ERC20/IERC20.sol";
import "./Common/ErrorHandler.sol";
import "./console.sol";
import "./STRUCTS/Transactions.sol";
import "contracts/Common/Interface/IAPY.sol";

contract APYMapper is Ownable{

    /// APY details struct
    struct APYDetail{
        address APYContract;
        uint256 APYPerentage;
    }

    /// APY Factory contract
    address public APYFactory;
    
    /// to save the detail of APY 
    APYDetail[] apyDetails;

    /// to save authentic users
    mapping(address => bool) public authenticUsers;
    
    /// just for convenience, user can see if a addess is an APY contract or not 
    mapping (address => bool) public isAPYExists;

    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_10);
        _;
    }

    /// initialize it with APY factory
    constructor(address _apyFactory){
        APYFactory = _apyFactory;
        authenticUsers[msg.sender] = true;
    }

    /// method used in APY Factory contract to save APY details in mapper
    function addAPYDetails(address _contractAddress, uint256 _apyAmount) external auth{
        APYDetail memory _APYDetail = APYDetail(_contractAddress, _apyAmount);
        isAPYExists[_contractAddress] = true;
        apyDetails.push(_APYDetail);
    }

    /// To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    /// To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    /// this method is used to set APY Factory contract
    function setAPYFactory(address _apyFactory) external onlyOwner{
        APYFactory = _apyFactory;
    }

    /// to get APY contract length
    function getAPYContractsLength() external view returns(uint256){
        return apyDetails.length;
    }

    /// to get APY contract addesses
    function getAPYContracts() external view returns (address[] memory){
        address[] memory result = new address[](apyDetails.length);
        
        for (uint256 i = 0; i < apyDetails.length; i++) {
            result[i] = apyDetails[i].APYContract;
        }
        return result;
    }

    /// to get APY contract details
    function getAPYContractsDetail() external view returns(APYDetail[] memory){
        return apyDetails;
    }

    /// to get latest APY contract
    function getLatestAPYContract() external view returns(address _latest){
        _latest = apyDetails[apyDetails.length-1].APYContract;
    }

    /// to get latest APY contract
    function getLatestAPYContractDetail() external view returns(APYDetail memory _latest){
        _latest = apyDetails[apyDetails.length-1];
    }
}