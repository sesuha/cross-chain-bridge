// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainBridge is Ownable {
    IERC20 public token;
    address public admin;

    mapping(bytes32 => bool) public processedNonces;

    event TokensLocked(address indexed user, uint256 amount, uint256 chainId, uint256 nonce);
    event TokensUnlocked(address indexed user, uint256 amount, uint256 chainId, uint256 nonce);

    constructor(address _token, address _admin) Ownable(_admin) {
        require(_token != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        
        token = IERC20(_token);
        admin = _admin;
    }

    function lockTokens(uint256 _amount, uint256 _chainId, uint256 _nonce) external {
        require(_amount > 0, "Amount must be greater than 0");
        bytes32 nonceKey = keccak256(abi.encodePacked(msg.sender, _amount, _chainId, _nonce));
        require(!processedNonces[nonceKey], "Transaction already processed");

        processedNonces[nonceKey] = true;

        token.transferFrom(msg.sender, address(this), _amount);

        emit TokensLocked(msg.sender, _amount, _chainId, _nonce);
    }

    function unlockTokens(address _user, uint256 _amount, uint256 _chainId, uint256 _nonce) external onlyAdmin {
        require(_user != address(0), "Invalid user address");
        require(_amount > 0, "Amount must be greater than 0");

        bytes32 nonceKey = keccak256(abi.encodePacked(_user, _amount, _chainId, _nonce));
        require(!processedNonces[nonceKey], "Transaction already processed");

        processedNonces[nonceKey] = true;

        token.transfer(_user, _amount);

        emit TokensUnlocked(_user, _amount, _chainId, _nonce);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not the admin");
        _;
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid admin address");
        admin = _admin;
    }
}