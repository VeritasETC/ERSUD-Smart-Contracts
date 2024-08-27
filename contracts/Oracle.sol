// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Common/ERC20/Ownable.sol";
import "./Common/ErrorHandler.sol";

contract OraclePrice is Ownable {
    /// ETC rate
    uint256 private ETHCRate;

    /// operator who will update ETC rate
    mapping(address => bool) public operator;

    /// intialize with operator address
    constructor(address _operatorAddress) {
        require(_operatorAddress != address(0),ErrorHandler.ZERO_ADDRESS);

        //ETHCRate = 2 * 10**18;
        ETHCRate = 9968260330000000000000;
        operator[_operatorAddress] = true;
        operator[msg.sender] = true;
    }

    /// used to get rate of ETC against USD
    function getAmount(uint256 _ethAmount) external view returns (uint256) {
        return (ETHCRate * _ethAmount) / 10 ** 18;
    }

    /// this method will update ETC rate and only operator and owner can call this method
    function setETHCRate(uint256 amount) external returns (bool) {
        require(
            msg.sender == owner() || operator[msg.sender],
            ErrorHandler.NOT_AUTHORIZED_7
        );
        ETHCRate = amount;
        return true;
    }

    /// to set operator, only owner can call this method
    function setOperator(address _userAddress) external onlyOwner {
        require(_userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        require(!operator[_userAddress], ErrorHandler.ALREADY_OPERATOR);
        operator[_userAddress] = true;
    }

    /// to remove operator, only owner can call this method
    function removeOperator(address _userAddress) external onlyOwner {
        require(_userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        require(operator[_userAddress], ErrorHandler.ALREADY_REMOVED);
        operator[_userAddress] = false;
    }
}
