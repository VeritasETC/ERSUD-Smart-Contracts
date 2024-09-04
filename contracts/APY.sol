// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Common/ERC20/Ownable.sol";
import "./console.sol";
import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 

/// @author SyedMokarramHashmi
/// @title APY rewards
contract APY {

    using SafeMath for uint256;

    mapping(address => bool) public authenticUsers;
    mapping(address => uint256) private userRewards;
    mapping(address => uint256) public lastReward;
    mapping(address => uint256) public userAPYAmount;
    mapping(address => bool) public userDeposited;
    mapping(address => bool) public withdrawUsers;
    mapping(address => bool) public APYUsers;

    modifier auth() {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_2);
        _;
    }

    modifier onlyManager() {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_2);
        _;
    }

    uint256 public APYPercentage;
    uint256 public deadTime;
    bool public live;
    uint256 public immutable daySeconds;
    address public vaultAddress;
    address public manager;
    uint256 public nextAPYStart;

    constructor() {
        // 5% APY
        APYPercentage = 13698630136986301;
        authenticUsers[msg.sender] = true;
        live = true;
        daySeconds = 86400; // 1 day = 24 h
        manager = msg.sender;
    }

    /// TODO: only factory can call this method
    function initialization(
        uint256 _apyPercent,
        address _actionContract,
        address _factoryContract,
        address _vaultContract,
        address _currentOwner,
        uint256 _nextAPYStart
    ) external {
        require(msg.sender == _factoryContract, ErrorHandler.NOT_FACTORY_CONTRACT);
        APYPercentage = _apyPercent;
        live = true;
        manager = _currentOwner;
        nextAPYStart = _nextAPYStart;
        vaultAddress = _vaultContract;
        authenticUsers[_actionContract] = true;
        authenticUsers[_factoryContract] = true;
        authenticUsers[manager] = true;
    }

    // set vault contract, only authorized caller can call it, it is not only owner becoz it will be called by other contacts too.
    function setVaultContract(address _vaultAddress) external auth {
        vaultAddress = _vaultAddress;
    }

    // To make someone authentic user
    function setAuthenticUser(address usr) external onlyManager {
        require(live, ErrorHandler.NOT_LIVE_6);
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true;
    }

    // To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyManager {
        require(live, ErrorHandler.NOT_LIVE_6);
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false;
    }

    /// to make the contract dead
    function cage() external auth {
        live = false;
        deadTime = block.timestamp;
    }

    function getCurrentDay(address _userAddress) internal view returns (uint256 _currentTime) {
        uint256 _dayCount;
        uint256 _lastRewardTime = IVault(vaultAddress).lastRewardTime(_userAddress);

        if (live) {
            _dayCount = (block.timestamp.sub(_lastRewardTime).add((daySeconds).sub(1))).div(daySeconds);
        } else {
            if (deadTime >= _lastRewardTime) {
                _dayCount = (deadTime.sub(_lastRewardTime).add((daySeconds).sub(1))).div(daySeconds);
            }
        }

        if (_dayCount == 0) {
            _currentTime = _lastRewardTime;
        } else {
            _currentTime = (daySeconds.mul(_dayCount)).add(_lastRewardTime);
        }
    }

    function getCurrentDayByLastRewardTime(address _userAddress) public view returns (uint256 _currentTime) {
        uint256 _dayCount;
        uint256 _lastRewardTime = IVault(vaultAddress).lastRewardTime(_userAddress);

        _dayCount = (nextAPYStart > _lastRewardTime) 
            ? (nextAPYStart.sub(_lastRewardTime)).div(daySeconds) 
            : 0;

        if (_dayCount == 0) {
            _currentTime = _lastRewardTime;
        } else {
            _currentTime = (daySeconds.mul(_dayCount)).add(_lastRewardTime);
        }
    }


    /// this method will be called when user call lockAndDraw method in action contact. it will update user last reward time
    function deposit(
        address _userAddress,
        uint256 _userAmount,
        uint256 _amount
    ) external auth {
        require(live, ErrorHandler.NOT_LIVE_6);
        if (_userAmount == 0) {
            //userDepositTime[_userAddress] = block.timestamp;
            IVault(vaultAddress).setLastRewardTime(
                _userAddress,
                block.timestamp
            );
            withdrawUsers[_userAddress] = false;
            APYUsers[_userAddress] = true;
        } else {
            (lastReward[_userAddress], ) = calculate(_userAddress);
            IVault(vaultAddress).setLastRewardTime(
                _userAddress,
                getCurrentDay(_userAddress)
            );
        }

        userAPYAmount[_userAddress] = (((_userAmount.add(_amount)).mul(APYPercentage)).div(10**20));
        userDeposited[_userAddress] = true;
    }

    /// user can get how much time passed when he deposited his amount
    function getTimePassed(
        address _userAddress
    ) external view returns (uint256) {
        return
            block.timestamp.sub(IVault(vaultAddress).userDepositTime(_userAddress));
    }

    /// This method is called when user withdraw his APY or collateral. If the contract dies, userAPY will set to zero.
    function resetAPYReward(
        address _userAddress,
        uint256 _amount
    ) external auth {
        lastReward[_userAddress] = 0;
        if (live == true) {
            IVault(vaultAddress).setLastRewardTime(
                _userAddress,
                getCurrentDay(_userAddress)
            );
            userAPYAmount[_userAddress] = (((_amount).mul(APYPercentage)).div(10**20));
        } else userAPYAmount[_userAddress] = 0;
        withdrawUsers[_userAddress] = true;
    }

    /// This method is used to calculate user aPY amount
    function calculate(
        address _userAddress
        ) public view returns (uint256 _APYAmount, uint256 _day) {
        uint256 _oneDay;
        uint256 _lastRewardTime = IVault(vaultAddress).lastRewardTime(_userAddress);
        uint256 _userDepositTime = IVault(vaultAddress).userDepositTime(_userAddress);
        
        bool isLoaner = IVault(vaultAddress).isLoaner(_userAddress);

        if (!isLoaner || !APYUsers[_userAddress] || withdrawUsers[_userAddress]) {
            _APYAmount = 0;
            _day = 0;
        } else {
            if (!live) {
                if (deadTime >= _lastRewardTime) {
                    _oneDay = (deadTime.sub(_lastRewardTime)).div(daySeconds);
                    _day = (deadTime.sub(_userDepositTime)).div(daySeconds);
                }
            } else {
                if (nextAPYStart != 0 && userAPYAmount[_userAddress] == 0) {
                    _oneDay = (!userDeposited[_userAddress])
                        ? (block.timestamp.sub(getCurrentDayByLastRewardTime(_userAddress))).div(daySeconds)
                        : (block.timestamp.sub(_lastRewardTime)).div(daySeconds);
                } else {
                    _oneDay = (block.timestamp.sub(_lastRewardTime)).div(daySeconds);
                }
                _day = (block.timestamp.sub(_userDepositTime)).div(daySeconds);
            }

            if (userDeposited[_userAddress]) {
                _APYAmount = lastReward[_userAddress].add((userAPYAmount[_userAddress]).mul(_oneDay));
            } else {
                uint256 _userAPYAmount = (IVault(vaultAddress).eth(_userAddress).mul(APYPercentage)).div(10**20);
                _APYAmount = lastReward[_userAddress].add((_userAPYAmount.mul(_oneDay)));
            }
        }
    }

}
