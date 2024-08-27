// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IOraclePrice.sol";
import "./Common/Interface/IAPYMapper.sol";
import "./Common/Interface/IETHJoin.sol";
import "./Common/ERC20/IERC20.sol";
import "./Common/Interface/ISwap.sol";
import "./Common/Interface/IERC20MintBurn.sol";
import "./console.sol";
import "./STRUCTS/TransactionEnums.sol";
import "./Common/Interface/IAPY.sol";

contract Liquidation is Ownable, TransactionEnums{

    /// Vault contract
    address public vaultContract;

    /// to get live rate of ETHC to USDT
    address public oracleAddress;

    /// to store liquidation penalty
    uint256 public liquidationPenalty;

    /// this address will liquidate collaterals and will get 4% of collateral as incentive fee
    address public masterWallet;

    /// incentive fee for keeper
    uint256 public incentiveFee;

    /// swap contract address
    address public swapContract;

    /// erusd contract address
    address public erusdContract;

    /// eth join smart contract address
    address public ethJoinContract;

    /// APY MApper contract
    address public APYMapper;
    
    
    /// initialize it with vault contract, oracle contract, masterWallet, ERUSD contract, ETHJoin contract and APY contract
    constructor(address _vaultContract, address _oracleAddress, address _masterWallet, address _erusdContract, address _ethJoinContract, address _APYMapper){
        require(_vaultContract != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_oracleAddress != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_masterWallet != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_erusdContract != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_ethJoinContract != address(0),ErrorHandler.ZERO_ADDRESS);
        require(_APYMapper != address(0),ErrorHandler.ZERO_ADDRESS);

        vaultContract = _vaultContract;
        oracleAddress = _oracleAddress;
        masterWallet = _masterWallet;
        erusdContract = _erusdContract;
        ethJoinContract = _ethJoinContract;
        APYMapper = _APYMapper;
        
        // 13% penalty is set by default
        liquidationPenalty = 13;
        
        // 4% incentive fee
        incentiveFee = 4;
    }

    
    /// this method is used to set mastet wallet, only owner can call this method.
    function setMasterWallet(address _masterWallet) external onlyOwner{
        require(_masterWallet != address(0), ErrorHandler.EMPTY_MASTER_WALLLET);
        masterWallet = _masterWallet;
    }

    /// this method is used to set liquidation penalty, only owner can call this method.
    function setLiquidationPenalty(uint256 _liqPercent) external onlyOwner{
        require(_liqPercent <= IVault(vaultContract).minCollateralRatio(), ErrorHandler.INVALID_PENALTY_AMOUNT);
        liquidationPenalty = _liqPercent;
    }

    /// this method is used to set vault contract address, only owner can call this method.
    function setVaultContract(address _vaultContract) external onlyOwner{
        vaultContract = _vaultContract;
    }
        
    /// this method is used to get user current liquidation penalty and next point of penalty
    function getLiquidationPercentage(address _userAddress) public view returns(uint256 _currentPercentage) {
        if(IVault(vaultContract).eth(_userAddress) > 0){
            uint256 _usdtAmount = IOraclePrice(oracleAddress).getAmount(IVault(vaultContract).eth(_userAddress));
            _currentPercentage = (_usdtAmount * 10 **20) / IVault(vaultContract).ERUSD(_userAddress);
        }
        else {
            _currentPercentage = 0;
        }
    }

    /// this method is used to get system health (collateral and total supply ratio)
    function getSystemHealth() external view returns(uint256 _health){
        if(IVault(vaultContract).totalCollatral() > 0){
            uint256 _usdtAmount = IOraclePrice(oracleAddress).getAmount(IVault(vaultContract).totalCollatral());
            //_health = (_usdtAmount * 10 **20) / IERC20MintBurn(erusdContract).totalSupply();
            _health = (_usdtAmount * 10 **20) / IVault(vaultContract).debt();
        }
        else 
        _health = 0;
    }

    /// This method is used to set swap contract. only owner can call this method
    function setSwapContract(address _swapContract) external onlyOwner{
        swapContract = _swapContract;
    }

    /// this method will only be called by masterwallet or owner of the contract
    function liquidateWithSwap(address _userAddress) external {

        uint256 _totalAPYAmount;

        require(swapContract != address(0), ErrorHandler.SET_SWAP_CONTRACT);

        require(masterWallet == msg.sender || owner() == msg.sender, ErrorHandler.NOT_AUTHORIZED_8);
        
        require(getLiquidationPercentage(_userAddress) <= (IVault(vaultContract).minCollateralRatio() - liquidationPenalty)*10**18, ErrorHandler.CANNOT_LIQUIDATE);

        (uint256 _userCollateral, uint256 _masterWalletFee) = getLiquidationDetail(_userAddress);
        
        // update user ERUSD record, make it zero becoz we have repaid it by liquidity
        IVault(vaultContract).suck(_userAddress, IVault(vaultContract).ERUSD(_userAddress), uint8(TransactionType.RepaidByLiquidity));
        
        //TODO: get_masterWalletFee + _userCollateral from vault contract to this contract
        IETHJoin(ethJoinContract).sendUserCollateral(_userAddress, address(this), _userCollateral + _masterWalletFee);
        
        // send incentive feet to master wallet
        payable (masterWallet).transfer(_masterWalletFee);

        // amount send to swap contract to run swap method
        payable (swapContract).transfer(_userCollateral);
        (, uint256 _acquire) = ISwap(swapContract).swap(erusdContract, masterWallet, _userCollateral);

        // burn token to decrease the supply
        IERC20MintBurn(erusdContract).burn(masterWallet, _acquire);

        // send APY to user
        address[] memory _APYs = IAPYMapper(APYMapper).getAPYContracts();
        for(uint256 x=0; x<_APYs.length; x++){
            (uint256 _APYAmount,) = IAPY(_APYs[x]).calculate(_userAddress);
            _totalAPYAmount += _APYAmount;
            IAPY(_APYs[x]).resetAPYReward(_userAddress, IVault(vaultContract).eth(_userAddress));
        }

        IETHJoin(ethJoinContract).withdrawAPYAmount(_userAddress, _totalAPYAmount);
        IVault(vaultContract).setTotalAPYSent(_totalAPYAmount);
        IVault(vaultContract).setUserInitialUSDTAmount(_userAddress, 0);
    }

    /// to get user's exact collateral according to debt, and 4% of incentive fee
    function getLiquidationDetail(address _userAddress) view public returns(uint256 _userCollateral, uint256 _masterWalletFee){
        
        // 500/150 = 3.33
        _userCollateral = (IVault(vaultContract).ERUSD(_userAddress) * 10**18) / IOraclePrice(oracleAddress).getAmount(1 ether);

        // find 4% of userCollateral as inventive fee
        _masterWalletFee = (IVault(vaultContract).eth(_userAddress) * incentiveFee)/100;
    }

    /// this method is used to set incentive fee, e-g, 4, or 5 etc
    function setIncentiveFee(uint256 _fee) external onlyOwner{
        incentiveFee = _fee;
    }

    function getLiquidityLimit() external view returns(uint256){
        return IVault(vaultContract).minCollateralRatio() - liquidationPenalty;
    }

    //. this method is used to set oracle contract address, only owner can call this method.
    function setOracleContract(address _oracleAddress) external onlyOwner{
        oracleAddress = _oracleAddress;
    }
    
    receive() external payable { }
    fallback() external payable { }
}
