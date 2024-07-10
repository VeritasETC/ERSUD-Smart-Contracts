// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/IERC20.sol";
import "./STRUCTS/TransactionEnums.sol";

contract ETCJoin is Ownable, TransactionEnums{
    
    /// mapping of authentic callers
    mapping(address => bool) public authenticUsers;
    
    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_4);
        _;
    }

    /// Active Flag
    bool public live;  

    /// address of vault contract
    address public vaultContract;

    /// Events
    event Join(address indexed usr, uint256 amount);
    event Fee(address indexed usr, uint256 amount);
    event Exit(address indexed usr, uint256 amount);
    event Cage();

    /// initialize vault contract
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
    
    /// to make the contract dead
    function cage() external auth {
        live = false;
        emit Cage();
    }

    /// to make the contract alive
    function wakeup() external auth {
        live = true;
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

    /// this method is used in withdraw collateral. only authentic person can call it
    function exit(address userAddress, uint256 amount, uint256 _APYAmout) external auth {
        require(live, ErrorHandler.NOT_LIVE_3); 
        require(amount >= 0, ErrorHandler.OVERFLOW_AMOUNT_2);
        
        // it will update user ETC record
        IVault(vaultContract).slip(userAddress, amount, uint8(TransactionType.Withdraw));
        
        // user will get back his collateral + APY amount
        payable(userAddress).transfer(amount + _APYAmout);
        IVault(vaultContract).setTotalAPYSent(_APYAmout);
        emit Exit(userAddress, amount);
    }

    /// this method is used to withdraw fee. only authentic caller can call it
    function withdrawFee(address _destination, uint256 _amount) external auth{
        require(_destination != address(0), ErrorHandler.ZERO_ADDRESS);
        require(_amount > 0 && _amount <= IVault(vaultContract).totalfeeCollected(), ErrorHandler.INVALID_AMOUNT);
        payable(_destination).transfer(_amount);
        IVault(vaultContract).updateTotalFeeCollected(_amount);
    }

    /// this method is used to withdraw APY, only authentic caller can call it
    function withdrawAPYAmount(address _userAddress, uint256 _amount) external auth{
        payable(_userAddress).transfer(_amount);
        IVault(vaultContract).withdrawAPYAmount(_userAddress, _amount);
    }

    /// this method is used to send exact user collateral based on his debt amount + incentive fee.
    function sendUserCollateral(address _userAddress, address _destination, uint256 _amount) external auth{
        require(_amount > 0, ErrorHandler.INVALID_AMOUNT);
        payable(_destination).transfer(_amount);
        IVault(vaultContract).slip(_userAddress, _amount, uint8(TransactionType.collateralLiquidate));
    }

    /// this method is used to set vault contract, only owner can call it
    function setVaultContract(address _vaultContract) public onlyOwner {
        vaultContract = _vaultContract;
    }

    /// to get ETC balance of this contract
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }

    /// in any emergency, owner can withdraw token from contract.
    function EmergencyWithdrawToken(address _tokenaddress, address _beneficiary, uint256 _amount) public onlyOwner{
        IERC20(_tokenaddress).transfer(_beneficiary, _amount);
    }

    /// in any emergency, owner can withdraw currency from contract.
    function EmergencyWithdrawCurrency(address _destionation, uint256 _amount) public onlyOwner {
        payable(_destionation).transfer(_amount);
    }

    receive() external payable { }
    fallback() external payable { }

}