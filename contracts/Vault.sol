// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./STRUCTS/VaultSTRUCT.sol";
import "./STRUCTS/UserAPY.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/ERC20/IERC20.sol";
import "./Common/ErrorHandler.sol";
//import "./console.sol";
import "./Common/Interface/IAPY.sol";
import "./Common/Interface/IOraclePrice.sol";
import "./Common/Interface/ITransactionHistory.sol";
import "contracts/STRUCTS/Transactions.sol";

contract Vault is Ownable, TransactionDetail{
    mapping(address => bool) public authenticUsers;

    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_6);
        _;
    }

    /// mapping to save the record of user locked ETHC
    mapping (address => uint256) public eth;

    /// mapping to save the record of user ERUSD debted
    mapping (address => uint256) public ERUSD;

    /// mapping to save the record of user ERUSD debted
    mapping (address => uint256) public userUSDTAmount;

    /// mapping of which address can call which address
    mapping(address => mapping (address => bool)) public can;

    /// total ERUSD debted
    uint256 public debt;

    /// contract activeness
    bool public live;

    /// totalfeeCollected
    uint256 public totalfeeCollected;

    /// totalCollatral
    uint256 public totalCollatral;

    /// totalAPYCollected
    uint256 public totalAPYCollected;

    /// minCollateralRatio
    uint256 public minCollateralRatio;

    /// locked Amount Time
    mapping(address => uint256) public lockedAmountTime;

    // is user Exists
    mapping(address => bool) public isUserExists;

    // user count
    uint256 public userCount;

    /// APY contract
    address public APYContract;

    /// Oracle price contract
    address public oracleAddress;

    /// Transaction History contract
    address public transactionContract;

    /// Loaner Users
    address[] private loanUsers;

    /// is a person a loaner
    mapping (address => bool) public isLoaner;

    constructor(address _APYContract, address _transacionHistory) {
        authenticUsers[msg.sender] = true;
        live = true;
        APYContract = _APYContract;
        minCollateralRatio = 150;

        transactionContract = _transacionHistory;
    }

    /// set the functionality of caller
    function hope(address fromAddress, address toAddress) external auth {
        can[fromAddress][toAddress] = true; 
    }
    
    /// remove caller address
    function nope(address fromContractAddress, address toContractAddress) external auth {
        can[fromContractAddress][toContractAddress] = false; 
    }
    
    // To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_5); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    // To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_5); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    /// to make the contract dead
    function cage() external auth {
        live = false;
    }

    /// set initial USDT of a user
    function setUserInitialUSDTAmount(address usr, uint256 usdtAmount) external auth{
        userUSDTAmount[usr] = usdtAmount;
    }

    /// method used to update collateral balance
    function lock(address usr, uint256 amount, uint256 fee) external auth {
        
        // Deposit functionality 
        IAPY(APYContract).deposit(usr, eth[usr], amount);
        eth[usr] += amount;

        if(!isUserExists[usr]){
            isUserExists[usr] = true;
            userCount++;
        }

        totalCollatral += amount;

        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType.Deposited);
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);

        _transacion = Transactions(block.timestamp, fee, TransactionType.FeeCollected);
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    /// method used to update ETHC balance of a user
    function slip(address usr, uint256 amount) external auth{
        require(eth[usr] > 0, ErrorHandler.INVALID_COLLATERAL_AMOUNT);
        
        if(ERUSD[usr] == 0){
            eth[usr] = 0;
            isLoaner[usr] = false;
            removeUser(usr);
        }
        else if(ERUSD[usr] < amount){
            eth[usr] = 0;    
        } 
        else 
        eth[usr] -= amount;
        
        if(!isUserExists[usr]){
            isUserExists[usr] = true;
            userCount++;
        }
        totalCollatral -= eth[usr];
        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType.Withdraw);
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    function removeUser(address _usr) internal {
        for(uint256 i=0; i<= loanUsers.length; i++){
            if(loanUsers[i] == _usr){
                removeFromArray(i);
                break;
            }
        }
    }

    /// private method use to pop up specfic value of an array
    function removeFromArray(uint256 index) private {
        address temp = loanUsers[index];
        loanUsers[index] = loanUsers[loanUsers.length-1];
        loanUsers[loanUsers.length-1] = temp;
        loanUsers.pop();
    }

    /// method used to update one address ERUSD balance to other address balance
    function draw(address usr, uint256 amount) external auth{
        lockedAmountTime[usr] = block.timestamp;
        ERUSD[usr] += amount;
        debt += amount;
        
        if(!isLoaner[usr]){
            isLoaner[usr] = true;
            loanUsers.push(usr);
        }
        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType.Generated);
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    function getLoanersLength() external view returns(uint256){
        return loanUsers.length;
    }
    
    function getLoaners(uint256 page, uint256 size) external view returns(address[] memory){
        
        uint256 ToSkip = page * size; //to skip
        uint256 count = 0;

        uint256 EndAt = loanUsers.length > ToSkip + size
            ? ToSkip + size
            : loanUsers.length;
        
        require(ToSkip < loanUsers.length, ErrorHandler.Vault_UNDER_FLOW);
        require(EndAt > ToSkip, ErrorHandler.Vault_UNDER_FLOW);

        address[] memory result = new address[](EndAt - ToSkip);

        for (uint256 i = ToSkip; i < EndAt; i++) {
            result[count] = loanUsers[i];
            count++;
        }
        return result;
    }

    /// method used to update one address ERUSD balance to other address balance
    function suck(address usr, uint256 amount) external auth{
        require(ERUSD[usr] >=  amount, ErrorHandler.INVALID_BORROW_AMOUNT);
        ERUSD[usr] -= amount;
        debt -= amount;
        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType.Repaid);
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    function withdrawAPYAmount(address _userAddress, uint256 _amount) external auth{
        Transactions memory _transacion = Transactions(block.timestamp, _amount, TransactionType.APYWithdraw);
        ITransactionHistory(transactionContract).addTransactions(_userAddress, _transacion);
    }

    /// method used to update ERUSD balance, only authentic caller can call it
    function updateERUSD(address _userAddress, uint256 _amount) external auth{
        ERUSD[_userAddress] -= _amount;
    }

    /// -- This functionality is not in use right now.
    /// Move ERUSD from one address to another address
    function move(address src, address dst, uint256 rad) external auth {
        require(check(src, msg.sender), "Vat/not-allowed");
        ERUSD[src] -= rad;
        ERUSD[dst] += rad;
    }

    function setTotalFeeCollected(uint256 _amount) external auth{
        totalfeeCollected += _amount;
    }

    function setTotalAPYSent(uint256 _amount) external auth{
        totalAPYCollected += _amount;
    }

    function updateTotalFeeCollected(uint256 _amount) external auth{
        require(_amount <= totalfeeCollected, "Invalid amount");
        totalfeeCollected -= _amount;
    }

    function setAPYContract(address _APYContract) external onlyOwner{
        APYContract = _APYContract;
    }

    function setMinCollateralRatio(uint256 _ratio) external onlyOwner{
        minCollateralRatio = _ratio;
    }

    /// not in used
    function check(address src, address caller) internal view returns (bool) {
        return either(src == caller, can[src][caller] == true);
    }

    /// not in used
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    
    /// not in used
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    receive() external payable { }
    fallback() external payable { }

}