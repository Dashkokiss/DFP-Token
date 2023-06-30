// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DFP is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant _CAP = 100_000_000e18;
    IERC20 private immutable _paymentToken;
    address private immutable _wallet;

    constructor(IERC20 paymentToken, address wallet) ERC20("DFP", "DFP") {
        _paymentToken = paymentToken;
        _wallet = wallet;

        _mint(address(this), _CAP);
    }

    function getPaymentToken() external view returns (address) {
        return address(_paymentToken);
    }
}
