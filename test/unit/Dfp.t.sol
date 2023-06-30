// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20Dec6} from "test/mock/MockERC20Dec6.sol";
import {DFP} from "src/Dfp.sol";

contract DfpTest is Test {
    DFP public dfp;
    MockERC20Dec6 internal mockErc20dec6;

    address internal ALICE = vm.addr(0xA11CE);
    address internal BOB = vm.addr(0xB0B);
    address internal OWNER = vm.addr(0xA);
    address internal WALLET = vm.addr(0xB);
    address internal HACKER = vm.addr(0xEBA);

    uint256 internal constant CAP = 100_000_000e18;
    uint256 internal constant VALUE = 1e18;
    uint256 internal constant DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    // region - Set Up

    function setUp() public {
        vm.label(ALICE, "ALICE");
        vm.label(BOB, "BOB");
        vm.label(OWNER, "Owner");
        vm.label(WALLET, "Wallet");
        vm.label(HACKER, "Hacker");

        mockErc20dec6 = new MockERC20Dec6("Mock Token", "MK");

        vm.prank(OWNER);
        dfp = new DFP(mockErc20dec6, WALLET);
    }

    function test_init() public {
        assertEq(dfp.name(), "DFP");
        assertEq(dfp.symbol(), "DFP");
        assertEq(dfp.decimals(), DECIMALS);
        assertEq(dfp.totalSupply(), CAP);
        assertEq(dfp.owner(), OWNER);
    }

    // endregion

    // region - getPaymentToken

    function test_getPaymentToken() public {
        assertEq(dfp.getPaymentToken(), address(mockErc20dec6));
    }

    // endregion

    // region - withdrawTokens

    function test_withdrawTokens_success() public {
        MockERC20Dec6 mockErc20 = new MockERC20Dec6("Mock Token", "MK");
        mockErc20.mint(address(dfp), VALUE);

        assertEq(mockErc20.balanceOf(address(dfp)), VALUE);

        vm.prank(OWNER);
        dfp.withdrawTokens(mockErc20, ALICE, VALUE);

        assertEq(mockErc20.balanceOf(address(dfp)), 0);
        assertEq(mockErc20.balanceOf(ALICE),  VALUE);
    }

    function test_withdrawTokens_dfp_success() public {
        vm.prank(OWNER);
        dfp.withdrawTokens(dfp, ALICE, VALUE);

        assertEq(dfp.balanceOf(ALICE), VALUE);
        assertEq(dfp.balanceOf(address(dfp)), dfp.totalSupply() - VALUE);
    }

    function test_withdrawTokens_emit_Transfer() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(dfp), ALICE, VALUE);

        vm.prank(OWNER);
        dfp.withdrawTokens(dfp, ALICE, VALUE);
    }

    function test_withdrawTokens_revert_ifNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(HACKER);
        dfp.withdrawTokens(dfp, HACKER, VALUE);
    }
    // endregion
}
