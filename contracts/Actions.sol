// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/Interface/IETHJoin.sol";
import "./Common/Interface/IVault.sol";
import "./Common/Interface/IERUSDJoin.sol";
import "./Common/Interface/IAPYMapper.sol";
import "./Common/Interface/IAPY.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IOraclePrice.sol";
import "./Common/Interface/IAPYFactory.sol";
import "./Common/ERC20/IERC20.sol";
import "./console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 

contract Actions is Ownable{

    using SafeMath for uint256;

    // ETH Join contract
    address public ethJoin;

    // ERUSD Join contract
    address public ERUSDJoin;

    // stability fee e-g, 4%
    uint256 public stabilityFee;

    // to get live rate of ETHC to USDT
    address public oracleAddress;

    // APY contract address
    address public APYContract;

    // APY contract address
    address public vaultContract;

    // address of APY Factory
    address public APYFactory;

    // address of APY mapper
    address public APYMapper;

    // address of APY mapper
    address public liquidation;
    
    // ethJoin contract address, ERUSD join contract address, oracle contract address, APY contract addres
    constructor(address _ethJoin, address _ERUSDJoin, address _oracleAddress, address _APYContract, address _vaultContract){
        require(_ethJoin != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_ERUSDJoin != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_oracleAddress != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_APYContract != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_vaultContract != address(0),ErrorHandler.ZERO_ADDRESS);
        
        ethJoin = _ethJoin;
        ERUSDJoin = _ERUSDJoin;
        stabilityFee = 4; // it is 4%, amount should be in integers
        oracleAddress = _oracleAddress;
        APYContract = _APYContract;
        vaultContract = _vaultContract;
    }

    /// this method is used to set apyMApper, only owner can call this
    function setAPYMapper(address _apyMapper) external onlyOwner{
        APYMapper = _apyMapper;
    }

    /// this method is used to set liquidation, only owner can call this
    function setLiquidationContract(address _liquidation) external onlyOwner{
        liquidation = _liquidation;
    }

    /// internal functions to call eth join and send ETH amount to EthJoin for lock
    function ethJoin_join(address _userAddress, uint256 _amount, uint256 _taxAmount) internal  {
        IETHJoin(ethJoin).join(_userAddress, _amount, _taxAmount);
    }

    /// internal functions to call ERUSD join and mint ERUSD token amount to ERUSDJoin
    function ERUSDJoin_join(address _userAddress, uint256 _amount) internal  {
        IERUSDJoin(ERUSDJoin).join(_userAddress, _amount);
    }

    /// This function is used to lock ETHC and draw (mint) ERUSD Tokens with specific collateral ratio
    function lockAndDraw(uint256 _tokenAmount, uint256 _collateralRatio) external payable {
        
        // collateralRatio should not be less than minimum collateral ratio
        require(_collateralRatio >= minCollateralRatio(), ErrorHandler.INVALID_RATIO);

        // calculate ETH amount
        uint256 calculatedAmount = getETHCalculatedAmount(_tokenAmount, _collateralRatio);
     
        // get ETC amount in USDT at current rate + previous rate
        uint256 _USDTAmount = IOraclePrice(oracleAddress).getAmount(calculatedAmount);
        _USDTAmount = _USDTAmount.add(IVault(vaultContract).userUSDTAmount(msg.sender));

        // set user initial usdt amount
        IVault(vaultContract).setUserInitialUSDTAmount(msg.sender, _USDTAmount);

        // deduct 4% stability fee
        uint256 _taxAmount = calculatedAmount.mul(stabilityFee).div(100);

        require(msg.value > _taxAmount, ErrorHandler.INVALID_TAX_AMOUNT);
        
        // remaing amount of ETH should be >= required amount of ETH to buy Tokens
        uint256 requiredAmount = calculatedAmount.add(_taxAmount);
        require(msg.value >= requiredAmount, ErrorHandler.LESS_ETH_AMOUNT);
        
        // call internal function
        ethJoin_join(msg.sender, calculatedAmount, _taxAmount);
        payable(ethJoin).transfer(requiredAmount);

        // remaining ETH is transferred back
        if (msg.value > requiredAmount) {
            uint256 refundAmount = msg.value - requiredAmount;
            payable(msg.sender).transfer(refundAmount);
        }
        
        // call join contract
        ERUSDJoin_join(msg.sender, _tokenAmount); 
       
    }

    /// this method will return total amount of ETC with current price.
    /// we are saving user USDT amount at the time when user deposited, and now we can get user's ETC amount.
    function getTotalETC(address _userAddress) public view returns(uint256 _amount){
        _amount = IVault(vaultContract).userUSDTAmount(_userAddress).mul(10 **18);
        _amount = _amount.div(IOraclePrice(oracleAddress).getAmount(1 ether));
    }

    /// withdraw collateral with specific amount
    function withdrawCollateral() external {
        uint256 _totalAPYAmount;
        IERUSDJoin(ERUSDJoin).exit(msg.sender, IVault(vaultContract).ERUSD(msg.sender));

        uint256 _ethAmount = getTotalETC(msg.sender);

        require(_ethAmount > 0, ErrorHandler.NO_COLLATERAL);

        address[] memory _APYs = IAPYMapper(APYMapper).getAPYContracts();

        // this loop will get collected APY reward from all APY contracts
        for(uint256 x=0; x<_APYs.length; x++){
            (uint256 _APYAmount,) = IAPY(_APYs[x]).calculate(msg.sender);    
            _totalAPYAmount += _APYAmount;
            IAPY(_APYs[x]).resetAPYReward(msg.sender, IVault(vaultContract).eth(msg.sender));
        }

        // check if contract have this amount of balance
        require( ethJoin.balance >= _totalAPYAmount.add(_ethAmount), ErrorHandler.INSUFFICIENT_FUND);
        
        // update the ETC and transfer it to user
        IETHJoin(ethJoin).exit(msg.sender, _ethAmount, _totalAPYAmount);

        // make the user USDT amount to zero
        IVault(vaultContract).setUserInitialUSDTAmount(msg.sender, 0);
    }

    function getUserTotalAPY(address _userAddress) external view returns(uint256 _amount){
        if(IVault(vaultContract).eth(_userAddress) > 0){
        address[] memory _APYs = IAPYMapper(APYMapper).getAPYContracts();
        for(uint256 x=0; x<_APYs.length; x++){
                (uint256 _APYAmount,) = IAPY(_APYs[x]).calculate(_userAddress);
                _amount += _APYAmount;
            }
        }
    }

    /// If user wants to withdraw seperate APY, user can call this method.
    function withdrawAPYAmount() external {
        address[] memory _APYs = IAPYMapper(APYMapper).getAPYContracts();
        uint8 _times;
        uint256 _totalAPYAmount;
        if(IVault(vaultContract).eth(msg.sender) > 0){
            for(uint256 x=0; x<_APYs.length; x++){

                (uint256 _APYAmount,) = IAPY(_APYs[x]).calculate(msg.sender);
                if(_APYAmount == 0)
                _times++;
                _totalAPYAmount += _APYAmount;
                IAPY(_APYs[x]).resetAPYReward(msg.sender, IVault(vaultContract).eth(msg.sender));
            }
            require(_times != _APYs.length, ErrorHandler.INVALID_APY_AMOUNT);
            IETHJoin(ethJoin).withdrawAPYAmount(msg.sender, _totalAPYAmount);
            IVault(vaultContract).setTotalAPYSent(_totalAPYAmount);
        }
        else 
        revert(ErrorHandler.NOT_ENOUGH_COLLATERAL);
    }

    function withdrawSingleAPYAmount(address _apyContract) external {
        if(IVault(vaultContract).eth(msg.sender) > 0){
            (uint256 _APYAmount,) = IAPY(_apyContract).calculate(msg.sender);
            IAPY(_apyContract).resetAPYReward(msg.sender, IVault(vaultContract).eth(msg.sender));    
            IETHJoin(ethJoin).withdrawAPYAmount(msg.sender, _APYAmount);
            IVault(_apyContract).setTotalAPYSent(_APYAmount);
        }
        else 
        revert(ErrorHandler.NOT_ENOUGH_COLLATERAL);
    }
    
    /// This method is used to set APY factory, only owner can call this method.
    function setAPYFactory(address _APYFactory) external onlyOwner{
        APYFactory = _APYFactory;
    }

    /// This method is used to update APY, only owner can call this method. It will create a seperete APY contract with new APY Percentage.
    function updateAPY(uint256 _apyPercentage, uint256 _daySeconds) external onlyOwner {
        address newAPYContract = IAPYFactory(APYFactory).createAPY(_apyPercentage, _daySeconds, msg.sender, address(this), vaultContract);        
        //vaultContract = newAPYContract;
        IVault(vaultContract).setAuthenticUser(newAPYContract);
        IVault(vaultContract).setAPYContract(newAPYContract);
        IAPY(newAPYContract).setAuthenticUser(vaultContract);
        IAPY(newAPYContract).setAuthenticUser(liquidation);
    }

    /// this method will return ETHC amount that a user will get when he put his tokenAmount ERUSD
    function getERUSDCalculatedAmount(uint256 _ETHCAmount) public view returns(uint256){
        uint256 _USDTRate = 1 ether *10**18 / (IOraclePrice(oracleAddress).getAmount(1 ether));
        return (_USDTRate.mul(_ETHCAmount)).div(10**18);
    }

    // to get ETH amount against token to buy with collateral ratio
    // function getETHCalculatedAmount(uint256 _tokenAmount, uint256 _collateralRatio) public view returns(uint256) {
    //     uint256 _oracleUSDAmount = IOraclePrice(oracleAddress).getAmount(1 ether);
    //     uint256 requireUSDAmount = (_collateralRatio * _tokenAmount) / 100;
        
    //     uint256 scaledAmount = (1 ether * requireUSDAmount * 1e18) / _oracleUSDAmount;
        
    //     return scaledAmount / 1e18;
    // }

    function getETHCalculatedAmount(uint256 _tokenAmount, uint256 _collateralRatio) public view returns (uint256) {
        uint256 _oracleUSDAmount  = IOraclePrice(oracleAddress).getAmount(1 ether);
        uint256 requireUSDAmount = (_collateralRatio.mul(_tokenAmount)).div(100);

         uint256 scaledAmount = ((requireUSDAmount).mul(1e18).mul(1 ether)).div(_oracleUSDAmount);
        
        return scaledAmount.div(1e18);
    }


    /// set stability fee, only owner can call this method.
    function setStabilityFee(uint256 _amount) external onlyOwner {
        stabilityFee = _amount;
    }
    
    /// set oracle contract address, only owner can call this method.
    function setOracleContract(address _oracleAddress) external onlyOwner{
        oracleAddress = _oracleAddress;
    }

    /// to get minimum collateral ratio
    function minCollateralRatio() public view returns(uint256){
        return IVault(vaultContract).minCollateralRatio();
    }

    /// this function is used to withdraw collected fee, only owner can call this method.
    function withdrawCollectedFee(address _masterWallet, uint256 _amount) external onlyOwner{
        IETHJoin(ethJoin).withdrawFee(_masterWallet, _amount);
    }
    
    receive() external payable { }
    fallback() external payable { }
}
