// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IOraclePrice.sol";
import "./Common/ERC20/IERC20.sol";
import "./console.sol";

contract Liquidation is Ownable{

    // Vault contract
    address public vaultContract;

    // to get live rate of ETHC to USDT
    address public oracleAddress;

    // to store liquidation penalty
    uint256 public liquidationPenalty;
    
    constructor(address _vaultContract, address _oracleAddress){
        vaultContract = _vaultContract;
        oracleAddress = _oracleAddress;
        
        // 13% penalty is set by default
        liquidationPenalty = 13;
    }

    /// this method is used to set liquidation penalty, only owner can call this method.
    function setLiquidationPenalty(uint256 _liqPercent) external onlyOwner{
        liquidationPenalty = _liqPercent;
    }

    /// this method is used to set vault contract address, only owner can call this method.
    function setVaultContract(address _vaultContract) external onlyOwner{
        vaultContract = _vaultContract;
    }
        
    /// this method is used to get user current liquidation penalty and next point of penalty
    function getLiquidationPercentage(address _userAddress) external view returns(uint256 _currenPercentage, uint256 _nextLiqPercent) {
        if(IVault(vaultContract).eth(_userAddress) > 0){
            uint256 _usdtAmount = IOraclePrice(oracleAddress).getAmount(IVault(vaultContract).eth(_userAddress));
            _currenPercentage = (100 * _usdtAmount) / IVault(vaultContract).ERUSD(_userAddress);
            uint256 _minRatio = IVault(vaultContract).minCollateralRatio();
            _nextLiqPercent = _minRatio - liquidationPenalty;
        }
        else {
            _currenPercentage = 0;
            _nextLiqPercent = 0;
        }
    }

    //. this method is used to set oracle contract address, only owner can call this method.
    function setOracleContract(address _oracleAddress) external onlyOwner{
        oracleAddress = _oracleAddress;
    }

    
    receive() external payable { }
    fallback() external payable { }
}
