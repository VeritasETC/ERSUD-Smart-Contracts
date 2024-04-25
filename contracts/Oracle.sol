// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Common/ERC20/Ownable.sol";
import "./Common/ErrorHandler.sol";

contract OraclePrice is Ownable{
    
    uint256 private ETHCRate;

    mapping (address => bool) public operator;
    constructor(address _operatorAddress){
        ETHCRate = 2 * 10**18;
        operator[_operatorAddress] = true;
        operator[msg.sender] = true;
    }

    function getAmount(uint256 _ethAmount) external view returns(uint256){
        return (ETHCRate * _ethAmount) / 10 ** 18;
    }

    function setETHCRate(uint256 amount) external returns(bool){
        require(msg.sender == owner() || operator[msg.sender], ErrorHandler.NOT_AUTHORIZED_7);
        ETHCRate = amount;
        return true;
    }

    function setOperator(address _userAddress) external onlyOwner{
        require(_userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        require(!operator[_userAddress], ErrorHandler.ALREADY_OPERATOR);
        operator[_userAddress] = true;
    }

    function removeOperator(address _userAddress) external onlyOwner{
        require(_userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        require(operator[_userAddress], ErrorHandler.ALREADY_REMOVED);
        operator[_userAddress] = false;
    }

}