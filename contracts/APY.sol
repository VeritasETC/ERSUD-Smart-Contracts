// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Common/ERC20/Ownable.sol";
import "./console.sol";
import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";

/// @author SyedMokarramHashmi
/// @title APY rewards
contract APY is Ownable {

    mapping(address => bool) public authenticUsers;
    mapping (address => uint256) private userAmount;
    mapping (address => uint256) private userDepositTime;
    mapping (address => uint256) private userRewards;
    mapping (address => uint256) private lastRewardTime;
    mapping (address => uint256) private lastReward;
    mapping (address => uint256) public userAPYAmount;

    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_2);
        _;
    }
    
    uint256 public APYPercentage;
    bool    public live;
    uint256 public daySeconds;

    constructor(){
        // 5% APY
        APYPercentage = 13698630136986301;
        authenticUsers[msg.sender] = true;
        live = true;
        daySeconds = 60;
    }

    // To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_1); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    // To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_1); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    function setDaySeconds(uint256 _seconds) external onlyOwner{
        daySeconds = _seconds;
    }

    function setAPYPercentage(uint256 _amount) external onlyOwner{
        APYPercentage = _amount;
    }

    /// to make the contract dead
    function cage() external auth {
        live = false;
    }

    function getCurrentDay(address _userAddress) internal view returns(uint256 _currentTime){
        uint256 _dayCount = uint32((block.timestamp - lastRewardTime[_userAddress])/daySeconds);
        if(_dayCount == 0)
        _currentTime = lastRewardTime[_userAddress];
        else
        _currentTime = ((daySeconds * _dayCount) + lastRewardTime[_userAddress]);
    }

    function deposit(address _userAddress, uint256 _userAmount, uint256 _amount) external auth {        
        require(live, ErrorHandler.NOT_LIVE_1); 
        if(_userAmount == 0){
            userDepositTime[_userAddress] = block.timestamp;
            lastRewardTime[_userAddress] = block.timestamp;
        }
        else{
            (lastReward[_userAddress],) = calculate(_userAddress);    
            lastRewardTime[_userAddress] = getCurrentDay(_userAddress);
        }
        
        userAPYAmount[_userAddress] = (((_userAmount + _amount) * APYPercentage) / 10**20 );
    }

    function getTimePassed(address _userAddress) external view returns(uint256){
        return block.timestamp - userDepositTime[_userAddress];
    }

    function resetAPYReward(address _userAddress, uint256 _amount) external auth{
        lastReward[_userAddress] = 0;
        lastRewardTime[_userAddress] = getCurrentDay(_userAddress);
        userAPYAmount[_userAddress] = (((_amount) * APYPercentage) / 10**20 );
    }

    function calculate(address _userAddress) public view returns(uint256 _APYAmount, uint256 _day){

        uint256 _oneDay = (block.timestamp - lastRewardTime[_userAddress]) / daySeconds;
        
        uint256 _amount = (lastReward[_userAddress] + (userAPYAmount[_userAddress]) * _oneDay);
        
        _APYAmount = _amount;
        _day = (block.timestamp - userDepositTime[_userAddress]) / daySeconds;
    }
}