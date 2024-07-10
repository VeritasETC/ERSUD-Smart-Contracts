// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAPYFactory {
        function createAPY( 
                    uint256 _apyPercentage, 
                    uint256 _daySeconds, 
                    address _currentOwner,
                    address _actionsContract,
                    address _vaultContract) external returns(address _newAPYContract);

}