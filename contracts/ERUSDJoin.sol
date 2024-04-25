// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Common/ERC20/Ownable.sol";
import "./Common/Interface/IVault.sol";
import "./Common/ErrorHandler.sol";
import "./Common/Interface/IERC20MintBurn.sol";
import "./Common/ERC20/IERC20.sol";

contract ERUSDJoin is Ownable{
    
    /// mapping of authentic callers
    mapping(address => bool) public authenticUsers;
    
    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_3);
        _;
    }

    /// status of the contract (active/deactive)
    bool public live;  // Active Flag

    /// address of vault contract
    address public vaultContract;

    /// address of ERUSD contract
    address public ERUSDAddress;

    // Events
    event Join(address indexed usr, uint256 amount);
    event Exit(address indexed usr, uint256 amount);
    event Cage();

    constructor(address _vaultContract, address _ERUSDAddress) {
        authenticUsers[msg.sender] = true;
        live = true;
        vaultContract = _vaultContract;
        ERUSDAddress = _ERUSDAddress;
    }

    /// To make someone authentic user
    function setAuthenticUser(address userAddress) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_1);
        require(userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[userAddress] = true; 
    }

    /// To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_2); 
        authenticUsers[usr] = false; 
    }

    /// authentic user can turn off the contract
    function cage() external auth {
        live = false;
        emit Cage();
    }

    /// this method will save the record of user into vault and mint given amount of token to this address.
    function join(address userAddress, uint256 amount) external auth {
        require(live, ErrorHandler.NOT_LIVE_1); 
        require(amount >= 0, ErrorHandler.OVERFLOW_AMOUNT_1);
        IVault(vaultContract).draw(userAddress, amount);
        IERC20MintBurn(ERUSDAddress).mint(userAddress, amount);
        emit Join(userAddress, amount);
    }

    /// this methods is called when user withdraw his collaterals, it burns user ERUSD tokens to maintain system peg.
    function exit(address userAddress, uint256 amount) external auth {
        require(live == true, ErrorHandler.NOT_LIVE_1);
        require(amount > 0, ErrorHandler.OVERFLOW_AMOUNT_1);
        
        // it will update user ERUSD record
        IVault(vaultContract).suck(userAddress, amount);
        // it will burn user tokens
        IERC20MintBurn(ERUSDAddress).burn(userAddress, amount);
        emit Exit(userAddress, amount);
    }

    /// this method is used to set vault contract address. only owner can call this method.
    function setVaultContract(address _vaultContract) external onlyOwner {
        vaultContract = _vaultContract;
    }

    receive() external payable { }
    fallback() external payable { }
}