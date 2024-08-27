// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Common/ERC20/Ownable.sol";
import "./Common/ErrorHandler.sol";
import "./Common/Interface/IAPY.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Common/Interface/IAPYMapper.sol";

contract APYFactory is Ownable{

    /// APY Mapper contract
    address public APYMapper;
    
    /// APY contract
    address public APYContract;
    
    /// count for making clone contract addesses unique
    uint256 public count;

    /// newly cloned APY contract
    address public newAPYContract;

    /// to save authentic users
    mapping(address => bool) public authenticUsers;

    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_11);
        _;
    }
    
    /// initialize APY contract 
    constructor(address _APYContract) {
        require(_APYContract != address(0),ErrorHandler.ZERO_ADDRESS);
        APYContract = _APYContract;
        authenticUsers[msg.sender] = true;
    }

    /// this method is responsible to create APY contract and initialize it with whatever parameters needed and add newly APY contract
    /// addres to mapper. and call cage method from previous APY contract to make it dead. So that user cannot get more reward from that
    /// contract.
    function createAPY(uint256 _apyPercentage, 
                    uint256 _daySeconds, 
                    address _currentOwner,
                    address _actionsContract,
                    address _vaultContract)
                    external auth returns(address APYContractClone){

        address _preAPYContract = IAPYMapper(APYMapper).getLatestAPYContract();
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, count, block.timestamp));
        newAPYContract = APYContractClone = Clones.cloneDeterministic(APYContract, salt);
        /// add address in mapper
        IAPYMapper(APYMapper).addAPYDetails(address(APYContractClone), _apyPercentage);

        IAPY(APYContractClone).initialization(_apyPercentage, _daySeconds, _actionsContract, address(this), _vaultContract, _currentOwner, block.timestamp);
        IAPY(_preAPYContract).cage();
        count++;
    }

    /// To make someone authentic user
    function setAuthenticUser(address usr) external onlyOwner {
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    /// To remove someone from authentic users
    function removeAuthenticUser(address usr) external onlyOwner {
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    /// set APY mapper contract
    function setAPYMapper(address _apyMapper) external onlyOwner{
        APYMapper = _apyMapper;
    }

}