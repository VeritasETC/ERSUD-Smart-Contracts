// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/Interface/IETHJoin.sol";
import "./Common/Interface/IVault.sol";
import "./Common/Interface/IERUSDJoin.sol";
import "./Common/Interface/IAPY.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IOraclePrice.sol";
import "./Common/ERC20/IERC20.sol";

contract Actions is Ownable{

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
    
    // ethJoin contract address, ERUSD join contract address, oracle contract address, APY contract addres
    constructor(address _ethJoin, address _ERUSDJoin, address _oracleAddress, address _APYContract, address _vaultContract){
        ethJoin = _ethJoin;
        ERUSDJoin = _ERUSDJoin;
        stabilityFee = 4; // it is 4%, amount should be in integers
        oracleAddress = _oracleAddress;
        APYContract = _APYContract;
        vaultContract = _vaultContract;
    }

    /// internal functions to call eth join and send ETH amount to EthJoin for lock
    function ethJoin_join(address _userAddress, uint256 _amount, uint256 _taxAmount) internal  {
        IETHJoin(ethJoin).join(_userAddress, _amount, _taxAmount);
        payable(ethJoin).transfer(_amount + _taxAmount);
    }

    /// internal functions to call ERUSD join and mint ERUSD token amount to ERUSDJoin
    function ERUSDJoin_join(address _userAddress, uint256 _amount) internal  {
        IERUSDJoin(ERUSDJoin).join(_userAddress, _amount);
    }

    /// This function is used to lock ETHC and draw (mint) ERUSD Tokens with specific collateral ratio
    function lockAndDraw(uint256 _tokenAmount, uint256 _collateralRatio) external payable {
        
        // collateralRatio should not be less than minimum collateral ratio
        require(_collateralRatio >= minCollateralRatio(), ErrorHandler.INVALID_RATIO);

        // get ETC amount in USDT at current rate + previous rate
        uint256 _USDTAmount = IOraclePrice(oracleAddress).getAmount(getETHCalculatedAmount(_tokenAmount, _collateralRatio));
        _USDTAmount = _USDTAmount + IVault(vaultContract).userUSDTAmount(msg.sender);

        // set user initial usdt amount
        IVault(vaultContract).setUserInitialUSDTAmount(msg.sender, _USDTAmount);

        // deduct 4% stability fee
        uint256 _taxAmount = (getETHCalculatedAmount(_tokenAmount, _collateralRatio) * stabilityFee) / 100;

        require(msg.value > _taxAmount, ErrorHandler.INVALID_TAX_AMOUNT);
        
        // remaing amount of ETH should be >= required amount of ETH to buy Tokens
        require(msg.value >= getETHCalculatedAmount(_tokenAmount, _collateralRatio) + _taxAmount, ErrorHandler.LESS_ETH_AMOUNT);
        
        // call internal function
        ethJoin_join(msg.sender, msg.value - _taxAmount, _taxAmount);
        
        // call join contract
        ERUSDJoin_join(msg.sender, _tokenAmount);
    }

    function getTotalETC(address _userAddress) public view returns(uint256 _amount){
        _amount = IVault(vaultContract).userUSDTAmount(_userAddress) * 10 **18;
        _amount = _amount/IOraclePrice(oracleAddress).getAmount(1 ether);
    }

    /// withdraw collateral with specific amount
    function withdrawCollateral() external {
        IERUSDJoin(ERUSDJoin).exit(msg.sender, IVault(vaultContract).ERUSD(msg.sender));

        uint256 _ethAmount = getTotalETC(msg.sender);

        require(_ethAmount > 0, "No Collateral");

        (uint256 _APYAmount,) = IAPY(APYContract).calculate(msg.sender);
        
        // update the ETC and transfer it to user
        IETHJoin(ethJoin).exit(msg.sender, _ethAmount, _APYAmount);
        
        IAPY(APYContract).resetAPYReward(msg.sender, IVault(vaultContract).eth(msg.sender));

        IVault(vaultContract).setUserInitialUSDTAmount(msg.sender, 0);
    }

    function withdrawAPYAmount() external {
        if(IVault(vaultContract).eth(msg.sender) > 0){
            (uint256 _APYAmount,) = IAPY(APYContract).calculate(msg.sender);
            //IAPY(APYContract).setUserAPYWithdraw(msg.sender, _APYAmount);
            IAPY(APYContract).resetAPYReward(msg.sender, IVault(vaultContract).eth(msg.sender));
            IETHJoin(ethJoin).withdrawAPYAmount(msg.sender, _APYAmount);
        }
        else 
        revert(ErrorHandler.NOT_ENOUGH_COLLATERAL);
    }

    /// this method will return ETHC amount that a user will get when he put his tokenAmount ERUSD
    function getERUSDCalculatedAmount(uint256 _ETHCAmount) public view returns(uint256){
        uint256 _USDTRate = 1 ether *10**18 / IOraclePrice(oracleAddress).getAmount(1 ether);
        return _USDTRate * _ETHCAmount / 10**18;
    }

    /// to get ETH amount against token to buy with collateral ratio
    function getETHCalculatedAmount(uint256 _tokenAmount, uint256 _collateralRatio) public view returns(uint256){
        uint256 _oracleUSDAmount = IOraclePrice(oracleAddress).getAmount(1*10**18);
        uint256 requireUSDAmount = (_collateralRatio * _tokenAmount) / 100;
        return  (1 ether * requireUSDAmount) / (_oracleUSDAmount);
    }

    /// set stability fee, only owner can call this method.
    function setStabilityFee(uint256 _amount) external onlyOwner {
        stabilityFee = _amount;
    }
    
    /// set oracle contract address, only owner can call this method.
    function setOracleContract(address _oracleAddress) external onlyOwner{
        oracleAddress = _oracleAddress;
    }

    function minCollateralRatio() public view returns(uint256){
        return IVault(vaultContract).minCollateralRatio();
    }

    /// this function is used to withdraw collected fee, only owner can call this method.
    // function withdrawCollectedFee(address _masterWallet, uint256 _amount) external onlyOwner{
    //     IETHJoin(ethJoin).withdrawFee(_masterWallet, _amount);
    // }
    
    receive() external payable { }
    fallback() external payable { }
}
