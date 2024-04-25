// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/IERC20.sol";

contract ETCJoin is Ownable{
    
    /// mapping of authentic callers
    mapping(address => bool) public authenticUsers;
    
    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_4);
        _;
    }

    bool public live;  // Active Flag

    /// address of vault contract
    address public vaultContract;

    // Events
    event Join(address indexed usr, uint256 amount);
    event Fee(address indexed usr, uint256 amount);
    event Exit(address indexed usr, uint256 amount);
    event Cage();

    constructor(address _vaultContract) {
        authenticUsers[msg.sender] = true;
        live = true;
         vaultContract = _vaultContract;
    }

    // To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_3); 
        authenticUsers[usr] = true; 
    }

    // To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_3); 
        authenticUsers[usr] = false; 
    }
    
    function cage() external auth {
        live = false;
        emit Cage();
    }

    /// this method will save the record of user into vault, assests will be sent to this address by action contract.
    function join(address userAddress, uint256 amount, uint256 feeAmount) external auth {
        require(live, ErrorHandler.NOT_LIVE_3); 
        require(amount >= 0, ErrorHandler.OVERFLOW_AMOUNT_2);
        IVault(vaultContract).lock(userAddress, amount, feeAmount);

        // amount will be set here 
        IVault(vaultContract).setTotalFeeCollected(feeAmount);
        emit Join(userAddress, amount);
        emit Fee(userAddress, feeAmount);
    }

    function exit(address userAddress, uint256 amount, uint256 _APYAmout) external auth {
        require(live, ErrorHandler.NOT_LIVE_3); 
        require(amount >= 0, ErrorHandler.OVERFLOW_AMOUNT_2);
        
        // it will update user ERUSD record
        IVault(vaultContract).slip(userAddress, amount);
        
        // user will get back his collateral + APY amount
        payable(userAddress).transfer(amount + _APYAmout);
        IVault(vaultContract).setTotalAPYSent(_APYAmout);
        emit Exit(userAddress, amount);
    }

    function withdrawFee(address _destination, uint256 _amount) external auth{
        require(_destination != address(0), ErrorHandler.ZERO_ADDRESS);
        require(_amount > 0, ErrorHandler.INVALID_AMOUNT);
        payable(_destination).transfer(_amount);
        IVault(vaultContract).updateTotalFeeCollected(_amount);
    }

    function withdrawAPYAmount(address _userAddress, uint256 _amount) external auth{
        require(_amount > 0, ErrorHandler.INVALID_AMOUNT);
        payable(_userAddress).transfer(_amount);
        IVault(vaultContract).withdrawAPYAmount(_userAddress, _amount);
    }

    function setVaultContract(address _vaultContract) public onlyOwner {
        vaultContract = _vaultContract;
    }

    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }

    function EmergencyWithdrawCurrency(address _destionation, uint256 _amount) public onlyOwner {
        payable(_destionation).transfer(_amount);
    }

    receive() external payable { }
    fallback() external payable { }

}