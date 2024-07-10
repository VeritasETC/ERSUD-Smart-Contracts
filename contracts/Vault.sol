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
import "./STRUCTS/Transactions.sol";

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

    // userDeposit time
    mapping(address => uint256) public userDepositTime;

    // user last reward time;
    mapping(address => uint256) public lastRewardTime;

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
    
    // To make someone authentic user
    function setAuthenticUser(address usr) external {
        require(owner() == msg.sender || authenticUsers[msg.sender], "VAULT/NOT_AUTHORIZED");
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

    /// to make the contract alive
    function wakeup() external auth {
        live = true;
    }

    /// set initial USDT of a user
    function setUserInitialUSDTAmount(address usr, uint256 usdtAmount) external auth{
        userUSDTAmount[usr] = usdtAmount;
    }

    /// method used to update collateral balance
    function lock(address usr, uint256 amount, uint256 fee) external auth {
        
        // Deposit functionality 
        IAPY(APYContract).deposit(usr, eth[usr], amount);
        if(eth[usr] == 0)
        userDepositTime[usr] = block.timestamp;
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
    function slip(address usr, uint256 amount, uint8 _transactionType) external auth{
        require(eth[usr] > 0, ErrorHandler.INVALID_COLLATERAL_AMOUNT);
        require(ERUSD[usr] == 0, ErrorHandler.ERUSD_MUST_BURN);
        
        eth[usr] = 0;
        isLoaner[usr] = false;
        removeUser(usr);
        
        // else if(ERUSD[usr] < amount){
        //     eth[usr] = 0;    
        // } 
        // else 
        // eth[usr] = 0;
        
        // if(!isUserExists[usr]){
        //     isUserExists[usr] = true;
        //     userCount++;
        // }
        //totalCollatral -= eth[usr];
        totalCollatral -= amount;
        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType(_transactionType));
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    
    // private method used to remove user from its array
    function removeUser(address _usr) private {
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

    // method used to get loaners length
    function getLoanersLength() external view returns(uint256){
        return loanUsers.length;
    }
    
    // set oracle contract address
    function setOracleContract(address _oracleContract) external onlyOwner{
        oracleAddress = _oracleContract;
    }

    // get all loaners with paginated, first page is zero 
    function getLoaners(uint256 page, uint256 size, uint256 ratio) external view returns(address[] memory){
        
        uint256 ToSkip = page * size; //to skip
        uint256 count = 0;

        uint256 EndAt = loanUsers.length > ToSkip + size
            ? ToSkip + size
            : loanUsers.length;
        
        require(ToSkip < loanUsers.length, ErrorHandler.Vault_UNDER_FLOW);
        require(EndAt > ToSkip, ErrorHandler.Vault_UNDER_FLOW);

        address[] memory result = new address[](EndAt - ToSkip);

        uint256 _currentPercentage;

        for (uint256 i = ToSkip; i < EndAt; i++) {
            uint256 _usdtAmount = IOraclePrice(oracleAddress).getAmount(eth[loanUsers[i]]);
            _currentPercentage = (_usdtAmount * 10 **20) / ERUSD[loanUsers[i]];
            if(_currentPercentage <= ratio){
                result[count] = loanUsers[i];
                count++;
            }
        }

        assembly {
            mstore(result, count)
        }
        return result;
    }

    /// method used to update one address ERUSD balance to other address balance
    function suck(address usr, uint256 amount, uint8 _transactionType) external auth{
        require(ERUSD[usr] >=  amount, ErrorHandler.INVALID_BORROW_AMOUNT);
        ERUSD[usr] -= amount;
        debt -= amount;
        Transactions memory _transacion = Transactions(block.timestamp, amount, TransactionType(_transactionType));
        ITransactionHistory(transactionContract).addTransactions(usr, _transacion);
    }

    /// method will be called by action contract, it is used to withdraw APY
    function withdrawAPYAmount(address _userAddress, uint256 _amount) external auth{
        Transactions memory _transacion = Transactions(block.timestamp, _amount, TransactionType.APYWithdraw);
        ITransactionHistory(transactionContract).addTransactions(_userAddress, _transacion);
    }

    /// method used to update ERUSD balance, only authentic caller can call it
    function updateERUSD(address _userAddress, uint256 _amount) external auth{
        ERUSD[_userAddress] -= _amount;
    }

    /// it is used to add fee collected during lockAndDraw method. It is called by action contract
    function setTotalFeeCollected(uint256 _amount) external auth{
        totalfeeCollected += _amount;
    }

    /// it is used to save the record of APY sent
    function setTotalAPYSent(uint256 _amount) external auth{
        totalAPYCollected += _amount;
    }

    /// this method is used to update collected fee amount, when owner withdraw fee, it will be updated
    function updateTotalFeeCollected(uint256 _amount) external auth{
        require(_amount <= totalfeeCollected, ErrorHandler.INVALID_FEE_AMOUNT);
        totalfeeCollected -= _amount;
    }

    /// this method is used to set APY contract, only owner can call it
    function setAPYContract(address _APYContract) external auth{
        APYContract = _APYContract;
    }

    /// this method is used to set minimum collateral ratio, and only be called by owner
    function setMinCollateralRatio(uint256 _ratio) external onlyOwner{
        minCollateralRatio = _ratio;
    }

    function setLastRewardTime(address _userAddress, uint256 _time) external auth{
        lastRewardTime[_userAddress] = _time;  
    }

}