//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUSDT} from "test/mock/interfaces/IUSDT.sol";

contract MockERC20Dec6 is ERC20, IUSDT {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function name() public view override(IUSDT, ERC20) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(IUSDT, ERC20) returns (string memory) {
        return super.symbol();
    }

    function decimals() public view virtual override(IUSDT, ERC20) returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function issue(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function owner() external returns (address) {}

    function transferOwnership(address newOwner) external {}
}
