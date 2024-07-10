// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/ERC20/Ownable.sol";
import "./Common/ERC20/IERC20.sol";
import "./Common/ErrorHandler.sol";
import "./console.sol";
import "./STRUCTS/Transactions.sol";

contract TransactionHistory is Ownable, TransactionDetail{
    
    /// save authentic callers
    mapping(address => bool) public authenticUsers;

    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_5);
        _;
    }

    /// contract activeness
    bool public live;

    /// total transctions
    uint256 public totalTransctions;

    /// user transaction record
    mapping (address => Transactions[]) public userTransactions;

    constructor() {
        //TODO: remove deployer from authentic users
        authenticUsers[msg.sender] = true;
        live = true;
    }

    /// To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_4); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    /// To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_4); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    /// to make the contract dead
    function cage() external auth {
        live = false;
    }

    /// this method is used to add transaction against users, it involves transaction type, amount and time
    function addTransactions(address _userAddress, Transactions memory _trans) external auth {
        userTransactions[_userAddress].push(_trans);
        totalTransctions++;
    }

    /// this method is used to get user transactions with paginated result. first page is ZERO.
    function getUserTransactions(address _userAddress, uint256 _page, uint256 _size) public view returns(Transactions[] memory _transactions) {
        uint256 ToSkip = _page * _size; //to skip
        uint256 count = 0;

        uint256 EndAt = userTransactions[_userAddress].length > ToSkip + _size
            ? ToSkip + _size
            : userTransactions[_userAddress].length;

        require(ToSkip < userTransactions[_userAddress].length, ErrorHandler.UNDER_FLOW);
        require(EndAt > ToSkip, ErrorHandler.OVER_FLOW);

        Transactions[] memory result = new Transactions[](EndAt - ToSkip);

        for (uint256 i = ToSkip; i < EndAt; i++) {
            result[count] = userTransactions[_userAddress][(userTransactions[_userAddress].length - 1)- (i)];
            count++;
        }
        return result;
    }

    /// this method is used to get user transaction length.
    function getUserTransactionLength(address _userAddress) external view returns (uint256){
        return userTransactions[_userAddress].length;
    }

}