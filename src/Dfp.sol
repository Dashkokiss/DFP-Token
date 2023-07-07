// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    ERC20,
    IERC20,
    ERC20Permit,
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DFP is ERC20Permit, ERC165, Ownable {
    using SafeERC20 for IERC20;

    /// @notice The minimum amount that can be purchased is set at 1 DFP
    uint256 public constant MIN_PURCHASE_AMOUNT = 1e18;

    /// @notice The rate at which tokens are sold is set at 0.1 USDT
    uint256 public constant SALE_RATE = 0.1e6;

    /// @notice Total supply of tokens is set at 100 million DFP
    uint256 private constant _TOTAL_SUPPLY = 100_000_000e18;

    /// @notice A multiplier used to calculate the price
    uint256 private constant _MULTIPLIER = 1e18;

    /// @notice The ERC20 token that will be used for payments
    IERC20 private immutable _paymentToken;

    /// @notice The wallet address of the seller
    address private immutable _sellerWallet;

    /// Errors

    /// @notice When an action is attempted involving a zero address
    error ZeroAddress();

    /// @notice When the amount being purchased is below the minimum purchase threshold
    error LessThanMinPurchase();

    /// @notice When there are not enough tokens available to fulfill a purchase
    error NotEnoughTokensToSell();

    /// Event

    /// @notice Emitted when tokens are successfully sold
    event Sold(address indexed buyer, address indexed recipient, uint256 amount);

    /**
     * @notice Contract constructor that initializes the token
     * @param paymentToken The address of the ERC20 token that will be used for payments
     * @param sellerWallet The wallet address to which payment is accepted
     * @dev Mints the total supply of DFP tokens to the contract's address
     */
    constructor(IERC20 paymentToken, address sellerWallet) ERC20("DFP", "DFP") ERC20Permit("DFP") {
        if (sellerWallet == address(0)) {
            revert ZeroAddress();
        }

        _paymentToken = paymentToken;
        _sellerWallet = sellerWallet;

        _mint(address(this), _TOTAL_SUPPLY);
    }

    /// @dev See {IERC165 - supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC20Permit).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Returns the address of the payment token
    function getPaymentToken() external view returns (address) {
        return address(_paymentToken);
    }

    /**
     * @notice Withdraws tokens from the contract and transfers them to a specified address
     * @param token The address of the ERC20 token contract
     * @param to The address where the tokens will be transferred
     * @param amount The amount of tokens to be withdrawn
     * @dev Only the owner of the contract can call this function
     */
    function withdrawTokens(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Allows a user to buy tokens by specifying the purchase amount
     * @param amount The amount of tokens to be purchased
     * @dev Calls the internal function _buy to handle the token purchase
     */
    function buy(uint256 amount) external {
        _buy(amount, msg.sender);
    }

    /**
     * @notice Allows a user to buy tokens by specifying the purchase amount and the recipient address
     * @param amount The amount of tokens to be purchased
     * @param recipient The address where the purchased tokens will be transferred
     * @dev Calls the internal function _buy to handle the token purchase
     */
    function buy(uint256 amount, address recipient) external {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }

        _buy(amount, recipient);
    }

    /**
     * @notice Internal function to handle the purchase of tokens
     * @param amount The amount of tokens to be purchased
     * @param recipient The address where the purchased tokens will be transferred
     * @dev Emits a Sold event to indicate the successful token purchase
     */
    function _buy(uint256 amount, address recipient) private {
        // Checks if the purchase amount is greater than the minimum purchase amount
        if (amount < MIN_PURCHASE_AMOUNT) {
            revert LessThanMinPurchase();
        }

        // Checks if the contract has enough tokens to sell
        if (balanceOf(address(this)) < amount) {
            revert NotEnoughTokensToSell();
        }

        // Calculates the purchase price based on the purchase amount and sale rate
        uint256 price = amount * SALE_RATE / _MULTIPLIER;

        // Transfers the payment from the buyer to the seller's wallet
        _paymentToken.safeTransferFrom(msg.sender, _sellerWallet, price);
        // Transfers the purchased tokens from the contract to the recipient address
        _transfer(address(this), recipient, amount);

        emit Sold(msg.sender, recipient, amount);
    }
}
