// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DFP is ERC20 {
    using SafeERC20 for IERC20;

    uint256 private constant _CAP = 100_000_000e18;

    constructor() ERC20("DFP", "DFP") {
        _mint(address(this), _CAP);
    }
}
