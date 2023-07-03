// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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
    uint256 private constant _MIN_PURCHASE_AMOUNT = 1e18;
    uint256 private constant _SALE_RATE = 0.1e6; // 0.1 USDT
    uint256 private constant _MULTIPLIER = 1e18;

    IERC20 private immutable _paymentToken;
    address private immutable _wallet;

    error MinPurchase(uint256 minAmount);

    event Sold(address indexed buyer, uint256 amount, uint256 price);

    constructor(IERC20 paymentToken, address wallet) ERC20("DFP", "DFP") ERC20Permit("DFP") {
        _paymentToken = paymentToken;
        _wallet = wallet;

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

    function getSalePrice(uint256 purchaseAmount) public pure returns (uint256 salePrice) {
        return (purchaseAmount * _SALE_RATE) / _MULTIPLIER;
    }

    function buyTokens(uint256 purchaseAmount) external {
        _purchaseTokens(purchaseAmount, _wallet);
    }

    function buyTokens(uint256 purchaseAmount, address wallet) external {
        _purchaseTokens(purchaseAmount, wallet);
    }

    function _purchaseTokens(uint256 purchaseAmount, address wallet) private {
        if (purchaseAmount < _MIN_PURCHASE_AMOUNT) {
            revert MinPurchase(_MIN_PURCHASE_AMOUNT);
        }

        uint256 purchasePrice = getSalePrice(purchaseAmount);
        assert(purchasePrice > 0);

        _paymentToken.safeTransferFrom(msg.sender, wallet, purchasePrice);
        _transfer(address(this), msg.sender, purchaseAmount);

        emit Sold(msg.sender, purchaseAmount, purchasePrice);
    }
}
