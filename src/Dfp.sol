// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    ERC20Permit,
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DFP is ERC20, ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant _CAP = 100_000_000e18;
    uint256 private constant _MULTIPLIER = 1e18;

    uint256 public constant MIN_PURCHASE_AMOUNT = 1e18;
    uint256 public constant SALE_RATE = 0.1e6; // 0.1 USDT

    IERC20 private immutable _paymentToken;
    address private immutable _sellerWallet;

    error ZeroAddress();
    error MinPurchase(uint256 minAmount);
    error NotEnoughTokensToSell();

    event Sold(
        address indexed buyer,
        address indexed recipientWallet,
        uint256 amount,
        uint256 price
    );

    constructor(IERC20 paymentToken, address sellerWallet) ERC20("DFP", "DFP") ERC20Permit("DFP") {
        if (sellerWallet == address(0)) {
            revert ZeroAddress();
        }

        _paymentToken = paymentToken;
        _sellerWallet = sellerWallet;

        _mint(address(this), _CAP);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC20Permit).interfaceId;
    }

    function withdrawTokens(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function getPaymentToken() external view returns (address) {
        return address(_paymentToken);
    }

    function buyTokens(uint256 purchaseAmount) external {
        _purchaseTokens(purchaseAmount, msg.sender);
    }

    function buyTokens(uint256 purchaseAmount, address recipientWallet) external {
        if (recipientWallet == address(0)) {
            revert ZeroAddress();
        }

        _purchaseTokens(purchaseAmount, recipientWallet);
    }

    function _purchaseTokens(uint256 purchaseAmount, address recipientWallet) private {
        if (purchaseAmount < MIN_PURCHASE_AMOUNT) {
            revert MinPurchase(MIN_PURCHASE_AMOUNT);
        }
        if (balanceOf(address(this)) < purchaseAmount) {
            revert NotEnoughTokensToSell();
        }

        uint256 purchasePrice = purchaseAmount * SALE_RATE / _MULTIPLIER;

        _paymentToken.safeTransferFrom(msg.sender, _sellerWallet, purchasePrice);
        _transfer(address(this), recipientWallet, purchaseAmount);

        emit Sold(msg.sender, recipientWallet, purchaseAmount, purchasePrice);
    }
}
