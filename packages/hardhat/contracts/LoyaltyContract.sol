// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LoyaltyContract
 * @dev A solidity smart contract for a loyalty app
 */
contract LoyaltyContract is Context, Ownable {
    // Token contract addresses
    address private _nftContract;
    address private _fungibleTokenContract;

    // Token details
    string private _nftName;
    string private _fungibleTokenName;
    string private _nftSymbol;
    string private _fungibleTokenSymbol;

    // Reward settings
    uint256 private _rewardAmount;
    bool private _isTransferable;

    // Mapping to track user token balances
    mapping(address => uint256) private _nftBalances;
    mapping(address => uint256) private _fungibleTokenBalances;

    // Events
    event TokenMinted(address indexed user, uint256 tokenId, uint256 amount);
    event RewardRedeemed(address indexed user, uint256 tokenId, uint256 amount);

    /**
     * @dev Initializes the contract setting the token contract addresses and reward details.
     *
     * The contract owner should invoke this function to set the initial parameters before usage.
     */
    constructor() {
        _nftContract = address(0);
        _fungibleTokenContract = address(0);
        _nftName = "NFT";
        _fungibleTokenName = "FungibleToken";
        _nftSymbol = "NFT";
        _fungibleTokenSymbol = "FT";
        _rewardAmount = 1;
        _isTransferable = true;
    }

    /**
     * @dev Sets the token contract addresses and reward details.
     *
     * @param nftContract The address of the NFT contract.
     * @param fungibleTokenContract The address of the fungible token contract.
     * @param nftName The name of the NFT token.
     * @param fungibleTokenName The name of the fungible token.
     * @param nftSymbol The symbol for the NFT token.
     * @param fungibleTokenSymbol The symbol for the fungible token.
     * @param rewardAmount The reward amount for token minting.
     * @param isTransferable Boolean indicating if tokens are transferable or not.
     */
    function setTokenDetails(
        address nftContract,
        address fungibleTokenContract,
        string memory nftName,
        string memory fungibleTokenName,
        string memory nftSymbol,
        string memory fungibleTokenSymbol,
        uint256 rewardAmount,
        bool isTransferable
    ) external onlyOwner {
        _nftContract = nftContract;
        _fungibleTokenContract = fungibleTokenContract;
        _nftName = nftName;
        _fungibleTokenName = fungibleTokenName;
        _nftSymbol = nftSymbol;
        _fungibleTokenSymbol = fungibleTokenSymbol;
        _rewardAmount = rewardAmount;
        _isTransferable = isTransferable;
    }

    /**
     * @dev Mints the reward token (either NFT or fungible token) to the user's address.
     * The user must have sufficient balance to cover the reward amount.
     */
    function mintToken() external {
        require(_nftContract != address(0) && _fungibleTokenContract != address(0), "Token contracts not set");
        if (_nftContract != address(0)) {
            IERC721 nft = IERC721(_nftContract);
            uint256 tokenId = nft.balanceOf(_msgSender()) + 1;
            nft.safeTransferFrom(address(this), _msgSender(), tokenId);
            _nftBalances[_msgSender()] += 1;
            emit TokenMinted(_msgSender(), tokenId, 1);
        }
        if (_fungibleTokenContract != address(0)) {
            IERC20 fungibleToken = IERC20(_fungibleTokenContract);
            fungibleToken.transferFrom(address(this), _msgSender(), _rewardAmount);
            _fungibleTokenBalances[_msgSender()] += _rewardAmount;
            emit TokenMinted(_msgSender(), 0, _rewardAmount);
        }
    }

    /**
     * @dev Redeems the reward token (either NFT or fungible token) by burning the token.
     * The user must have sufficient balance of the token to redeem.
     */
    function redeemReward() external {
        require(_nftContract != address(0) || _fungibleTokenContract != address(0), "No token contracts set");
        if (_nftContract != address(0)) {
            require(_nftBalances[_msgSender()] > 0, "Insufficient NFT balance");
            IERC721 nft = IERC721(_nftContract);
            uint256 tokenId = nft.balanceOf(_msgSender()) - (_nftBalances[_msgSender()] - 1);
            nft.safeTransferFrom(_msgSender(), address(this), tokenId);
            _nftBalances[_msgSender()] -= 1;
            emit RewardRedeemed(_msgSender(), tokenId, 1);
        }
        if (_fungibleTokenContract != address(0)) {
            require(_fungibleTokenBalances[_msgSender()] >= _rewardAmount, "Insufficient fungible token balance");
            IERC20 fungibleToken = IERC20(_fungibleTokenContract);
            fungibleToken.transferFrom(_msgSender(), address(this), _rewardAmount);
            _fungibleTokenBalances[_msgSender()] -= _rewardAmount;
            emit RewardRedeemed(_msgSender(), 0, _rewardAmount);
        }
    }

    /**
     * @dev Gets the NFT balance of a user.
     * 
     * @param account The address of the user.
     * @return The NFT balance of the user.
     */
    function getNFTBalance(address account) external view returns (uint256) {
        return _nftBalances[account];
    }

    /**
     * @dev Gets the fungible token balance of a user.
     * 
     * @param account The address of the user.
     * @return The fungible token balance of the user.
     */
    function getFungibleTokenBalance(address account) external view returns (uint256) {
        return _fungibleTokenBalances[account];
    }

    /**
     * @dev Sets the transferability of the reward tokens.
     * Only the contract owner can invoke this function.
     * 
     * @param isTransferable Boolean indicating if tokens are transferable or not.
     */
    function setTokenTransferability(bool isTransferable) external onlyOwner {
        _isTransferable = isTransferable;
    }

    /**
     * @dev Checks whether the reward tokens are transferable or not.
     * 
     * @return Boolean indicating if tokens are transferable or not.
     */
    function isTokenTransferable() external view returns (bool) {
        return _isTransferable;
    }
}