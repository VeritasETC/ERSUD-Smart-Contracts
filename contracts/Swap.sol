// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Common/ERC20/Ownable.sol";
import "./Common/ErrorHandler.sol";
import "./Common/ERC20/IERC20.sol";
import "./STRUCTS/ZumiSwapAmountParams.sol";
import "./Common/Interface/IZumiSwap.sol";

interface IWETH{
    function deposit() external payable;
}

contract Swap is Ownable, ZumiSwapAmountParams{
    
    /// mapping of authentic callers
    mapping(address => bool) public authenticUsers;

    
    modifier auth {
        require(authenticUsers[msg.sender], ErrorHandler.NOT_AUTHORIZED_9);
        _;
    }

    /// IZumi Swap contract address
    address public iZumiSwapContract;

    /// Wrap ETC address
    address public WETH9;

    /// liquidity fee which was set during add liquidity
    uint24 public fee;

    /// contract life
    bool public live;
    
    
    /// initialize with swap contract and fee is set to 2000 = 0.2%
    constructor(address _iZumiSwapContract){
        require(_iZumiSwapContract != address(0),ErrorHandler.ZERO_ADDRESS);

        authenticUsers[msg.sender] = true;
        iZumiSwapContract = _iZumiSwapContract; // 0x4bD007912911f3Ee4b4555352b556B08601cE7Ce
        WETH9 = IZumiSwap(iZumiSwapContract).WETH9();
        fee = 2000;
        live = true;
    }

    /// to set authentic caller, ony owner can call this method.
    function setAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_1); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = true; 
    }

    // To remove someone from authentic users, only owner can call thie method
    function removeAuthenticUser(address usr) external onlyOwner {
        require(live, ErrorHandler.NOT_LIVE_1); 
        require(usr != address(0), ErrorHandler.ZERO_ADDRESS);
        authenticUsers[usr] = false; 
    }

    /// to make the contract dead
    function cage() external auth {
        live = false;
    }

    /// to make the contract alive
    function wakeup() external auth {
        live = true;
    }

    /// this methiod is calling swap of IZumi swap contract, and it returns cost and acquire (how much token we will get) after swap
    /// this method is only be called by authentic caller.
    function swap(address _erusdToken, address _destination, uint256 _amount) external auth returns(uint256 cost, uint256 acquire) {
        bytes memory _path = getPath(WETH9, fee, _erusdToken);
        SwapAmountParams memory _params;
        _params.path = _path;
        _params.recipient = _destination;
        _params.amount = uint128(_amount);
        _params.deadline = block.timestamp + 1 days;
        _params.minAcquired = 0;

        IWETH(WETH9).deposit{value: _amount}();
        IERC20(WETH9).approve(iZumiSwapContract, _amount);
        (cost, acquire) = IZumiSwap(iZumiSwapContract).swapAmount(_params);
    }

    /// this method is returning path of tokens and fee in bytes.
    function getPath(address _token1, uint24 _fee, address _token2) private pure returns(bytes memory _path){
        _path = abi.encodePacked(_token1, _fee, _token2);
    }

    /// this method used to set swap contract address, only owner can call this method.
    function setZumiSwapContract(address _contractAddress) external onlyOwner{
        iZumiSwapContract = _contractAddress;
    }

    /// owner can also set WETC address.
    function setWETH9(address _tokenAddress) external onlyOwner{
        WETH9 = _tokenAddress;
    }

    /// owner can set liquidaity fee which is using to swap tokens
    function setSwapFee(uint24 _fee) external onlyOwner{
        fee = _fee;
    }

    /// to withdraw currency by owner in emergency
    function emergencyWithdrawCurrency(address _destination, uint256 _amount) external onlyOwner{
        payable (_destination).transfer(_amount);
    }

    /// to withdraw token by owner in emergency
    function emergencyWithdrawToken(address _tokenAddress, address _destination, uint256 _amount) external onlyOwner{
        IERC20(_tokenAddress).transfer(_destination, _amount);
    }

    receive() external payable { }
    fallback() external payable { }

}