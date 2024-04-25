// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Common/ERC20/ERC20.sol";
import "./Common/ERC20/ERC20Burnable.sol";
import "./Common/ERC20/ERC20Permit.sol";
import "./Common/ERC20/Ownable.sol";
import "./Common/ErrorHandler.sol";

contract ERUSD is ERC20, Ownable, ERC20Burnable, ERC20Permit("ERUSD") {
    
    /// mapping of authentic persons or contracts
    mapping(address => bool) public authentedPersons;
    
    modifier auth(){
        require(authentedPersons[msg.sender], ErrorHandler.NOT_AUTHORIZED_1);
        _;
    }

    constructor() ERC20("ERUSD test2", "TestERUSD2") {
        authentedPersons[msg.sender] = true;
    }

    /// set authentic caller, only authentic person can call this method.
    function setAuthenticUser(address userAddress) public onlyOwner {
        require(userAddress != address(0), ErrorHandler.ZERO_ADDRESS);
        authentedPersons[userAddress] = true;
    }

    /// remove authentic caller, only authentic person can call this method.
    function removeAuthectedPerson(address userAddress) public onlyOwner {
        authentedPersons[userAddress] = false;
    }

    /// mint tokens, only authentic caller can call this method.
    function mint(address userAddress, uint256 amount) public auth{
        _mint(userAddress, amount);
    }

    function burn(address userAddress, uint256 amount) public override auth{
        _burn(userAddress, amount);
    }

    function burnFrom(address userAddress, uint256 amount) public override auth{
        _burn(userAddress, amount);
    }

}