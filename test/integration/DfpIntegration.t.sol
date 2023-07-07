// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Test} from "forge-std/Test.sol";

import {IUSDT} from "test/mock/interfaces/IUSDT.sol";
import {MockERC20Dec6} from "test/mock/MockERC20Dec6.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DFP} from "src/Dfp.sol";

contract DfpIntegrationTest is Test {
    using SafeERC20 for IUSDT;

    DFP internal dfp;
    IUSDT internal usdt;

    address internal ALICE = vm.addr(0xA11CE);
    address internal BOB = vm.addr(0xB0B);
    address internal OWNER = vm.addr(0xA);

    uint256 internal constant SALE_RATE = 0.1e6; // 0.1 USDT
    uint256 internal constant MULTIPLIER = 1e18;

    address internal wallet;

    // region - Set Up

    function setUp() public {
        vm.label(ALICE, "ALICE");
        vm.label(BOB, "BOB");
        vm.label(OWNER, "Owner");

        uint256 chainId = block.chainid;

        if (chainId == 1) {
            HelperConfig helperConfig = new HelperConfig();
            address usdtAddr;

            (usdtAddr, wallet) = helperConfig.activeNetworkConfig();
            usdt = IUSDT(usdtAddr);

            vm.prank(usdt.owner());
            usdt.transferOwnership(OWNER);
        } else if (chainId == 11155111 || chainId == 31337) {
            usdt = new MockERC20Dec6("Tether USD", "MUSDT");
            wallet = vm.addr(0xBA);
        }

        vm.prank(OWNER);
        dfp = new DFP(usdt, wallet);
    }

    // endregion

    // region - Initial state

    function test_initialState() public {
        uint256 chainId = block.chainid;
        if (chainId == 1) {
            assertEq(usdt.name(), "Tether USD");
            assertEq(usdt.symbol(), "USDT");
            assertEq(usdt.decimals(), 6);
            assertGt(usdt.totalSupply(), 0);
        } else {
            assertEq(usdt.name(), "Tether USD");
            assertEq(usdt.symbol(), "MUSDT");
            assertEq(usdt.decimals(), 6);
            assertEq(usdt.totalSupply(), 0);
        }
    }

    // endregion

    // region - Buy tokens withoutWallet

    function test_buy_withoutWallet() public {
        uint256 totalUsdt = 10_000_000e6;
        uint256 purchaseAmount = 10_000_000e18;

        vm.prank(OWNER);
        usdt.issue(totalUsdt);

        for (uint256 i; i < 10; i++) {
            uint256 purchasePrice = purchaseAmount * SALE_RATE / MULTIPLIER;
            address user = vm.addr(i + 1);

            vm.prank(OWNER);
            usdt.safeTransfer(user, purchasePrice);

            vm.startPrank(user);
            usdt.safeApprove(address(dfp), purchasePrice);

            dfp.buy(purchaseAmount);

            assertEq(dfp.balanceOf(user), purchaseAmount);
            vm.stopPrank();
        }

        assertEq(usdt.balanceOf(wallet), totalUsdt);
        assertEq(dfp.balanceOf(address(dfp)), 0);
    }

    // endregion

    // region - Buy tokens withWallet

    function test_buy_withWallet() public {
        uint256 totalUsdt = 10_000_000e6;
        uint256 purchaseAmount = 10_000_000e18;

        vm.prank(OWNER);
        usdt.issue(totalUsdt);

        for (uint256 i; i < 10; i++) {
            uint256 purchasePrice = purchaseAmount * SALE_RATE / MULTIPLIER;
            address user = vm.addr(i + 1);

            vm.prank(OWNER);
            usdt.safeTransfer(user, purchasePrice);

            vm.startPrank(user);
            usdt.safeApprove(address(dfp), purchasePrice);

            dfp.buy(purchaseAmount, BOB);

            assertEq(dfp.balanceOf(user), 0);
            vm.stopPrank();
        }

        assertEq(usdt.balanceOf(wallet), totalUsdt);
        assertEq(dfp.balanceOf(BOB), dfp.totalSupply());
        assertEq(dfp.balanceOf(address(dfp)), 0);
    }

    // endregion

    // region - Withdraw USDT

    function test_withdraw_usdt() public {
        uint256 amount = 1_000e6;
        vm.startPrank(OWNER);
        usdt.issue(amount);

        usdt.safeTransfer(address(dfp), amount);

        assertEq(usdt.balanceOf(address(dfp)), amount);
        assertEq(usdt.balanceOf(ALICE), 0);

        dfp.withdraw(usdt, ALICE, amount);
        vm.stopPrank();

        assertEq(usdt.balanceOf(address(dfp)), 0);
        assertEq(usdt.balanceOf(ALICE), amount);
    }

    // endregion

    // region - Withdraw DFP

    function test_withdraw_dfp() public {
        uint256 amount = dfp.totalSupply();

        assertEq(dfp.balanceOf(address(dfp)), amount);
        assertEq(dfp.balanceOf(ALICE), 0);

        vm.prank(OWNER);
        dfp.withdraw(dfp, ALICE, amount);

        assertEq(dfp.balanceOf(address(dfp)), 0);
        assertEq(dfp.balanceOf(ALICE), amount);
    }

    // endregion
}
