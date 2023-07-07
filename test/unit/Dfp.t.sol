// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {
    IERC20Permit, IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {Test, console} from "forge-std/Test.sol";

import {MockERC20Dec6} from "test/mock/MockERC20Dec6.sol";
import {DepositMock} from "test/mock/DepositMock.sol";
import {SigUtils} from "test/utils/SigUtils.sol";
import {DFP} from "src/Dfp.sol";

contract DfpTest is Test {
    DFP public dfp;
    DepositMock internal deposit;
    MockERC20Dec6 internal paymentToken;
    SigUtils internal sigUtils;

    address internal ALICE = vm.addr(0xA11CE);
    address internal BOB = vm.addr(0xB0B);
    address internal OWNER = vm.addr(0xA);
    address internal WALLET = vm.addr(0xB);
    address internal HACKER = vm.addr(0xEBA);

    uint256 internal constant CAP = 100_000_000e18;
    uint256 internal constant VALUE = 1e18;
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant MIN_PURCHASE_AMOUNT = 1e18;
    uint256 internal constant SALE_RATE = 0.1e6; // 0.1 USDT
    uint256 internal constant MULTIPLIER = 1e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Sold(address indexed buyer, address indexed recipientWallet, uint256 amount);

    // region - Set Up

    function setUp() public {
        vm.label(ALICE, "ALICE");
        vm.label(BOB, "BOB");
        vm.label(OWNER, "Owner");
        vm.label(WALLET, "Wallet");
        vm.label(HACKER, "Hacker");

        paymentToken = new MockERC20Dec6("Mock Token", "MK");
        deposit = new DepositMock();

        vm.prank(OWNER);
        dfp = new DFP(paymentToken, WALLET);

        sigUtils = new SigUtils(dfp.DOMAIN_SEPARATOR());
    }

    function test_init() public {
        assertEq(dfp.name(), "DFP");
        assertEq(dfp.symbol(), "DFP");
        assertEq(dfp.decimals(), DECIMALS);
        assertEq(dfp.totalSupply(), CAP);
        assertEq(dfp.owner(), OWNER);
    }

    // endregion

    // region - constructor

    function test_constructor_revert_ifZeroAddress() public {
        vm.expectRevert(DFP.ZeroAddress.selector);
        dfp = new DFP(paymentToken, address(0));
    }

    // endregion

    // region - Support interfaces

    function test_supportInterface() public {
        bytes4 interfaceIdPermit = type(IERC20Permit).interfaceId;
        bytes4 interfaceIdERC165 = type(IERC165).interfaceId;
        bytes4 incorrectInterface = type(IERC20).interfaceId;

        assertTrue(dfp.supportsInterface(interfaceIdERC165));
        assertTrue(dfp.supportsInterface(interfaceIdPermit));

        assertFalse(dfp.supportsInterface(incorrectInterface));
    }

    // endregion

    // region - getPaymentToken

    function test_getPaymentToken() public {
        assertEq(dfp.getPaymentToken(), address(paymentToken));
    }

    // endregion

    // region - buy (without wallet)

    function test_buy_withoutWallet_revert_ifLessThanMinPurchase() public {
        vm.expectRevert(DFP.LessThanMinPurchase.selector);

        dfp.buy(MIN_PURCHASE_AMOUNT - 1);
    }

    function test_buy_withoutWallet_revert_ifInsufficientTokenToSell() public {
        vm.prank(OWNER);
        dfp.withdraw(dfp, OWNER, 100_000_000e18);

        vm.expectRevert(abi.encodeWithSelector(DFP.InsufficientTokenToSell.selector));
        dfp.buy(VALUE, ALICE);
    }

    function test_buy_withoutWallet_emit_Sold() public {
        uint256 purchasePrice = VALUE * SALE_RATE / MULTIPLIER;
        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);

        vm.expectEmit(true, true, true, true);
        emit Sold(ALICE, ALICE, VALUE);

        dfp.buy(VALUE);
    }

    function test_buy_withoutWallet_success() public {
        uint256 purchasePrice = CAP * SALE_RATE / MULTIPLIER;
        assertEq(purchasePrice, 10_000_000e6);

        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);

        dfp.buy(CAP);

        assertEq(dfp.balanceOf(ALICE), CAP);
        assertEq(dfp.balanceOf(address(dfp)), 0);
        assertEq(paymentToken.balanceOf(WALLET), purchasePrice);
    }

    function testFuzz_buy_withoutWallet(uint256 purchaseAmount) public {
        purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, CAP);

        uint256 purchasePrice = purchaseAmount * SALE_RATE / MULTIPLIER;

        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);
        dfp.buy(purchaseAmount);

        assertEq(dfp.balanceOf(ALICE), purchaseAmount);
        assertEq(paymentToken.balanceOf(WALLET), purchasePrice);
    }

    // endregion

    // region - buy (with wallet)

    function test_buy_withWallet_revert_ifLessThanMinPurchase() public {
        vm.expectRevert(DFP.LessThanMinPurchase.selector);

        dfp.buy(MIN_PURCHASE_AMOUNT - 1, ALICE);
    }

    function test_buy_withWallet_revert_ifInsufficientTokenToSell() public {
        vm.prank(OWNER);
        dfp.withdraw(dfp, OWNER, 100_000_000e18);

        vm.expectRevert(abi.encodeWithSelector(DFP.InsufficientTokenToSell.selector));
        dfp.buy(VALUE);
    }

    function test_buy_withWallet_revert_ifZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(DFP.ZeroAddress.selector));
        dfp.buy(VALUE, address(0));
    }

    function test_buy_withWallet_emit_Sold() public {
        uint256 purchasePrice = VALUE * SALE_RATE / MULTIPLIER;
        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);

        vm.expectEmit(true, true, true, true);
        emit Sold(ALICE, BOB, VALUE);

        dfp.buy(VALUE, BOB);
    }

    function test_buy_withWallet_success() public {
        uint256 purchasePrice = CAP * SALE_RATE / MULTIPLIER;
        assertEq(purchasePrice, 10_000_000e6);

        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);

        dfp.buy(CAP, BOB);

        assertEq(dfp.balanceOf(ALICE), 0);
        assertEq(dfp.balanceOf(BOB), CAP);
        assertEq(dfp.balanceOf(address(dfp)), 0);
        assertEq(paymentToken.balanceOf(WALLET), purchasePrice);
    }

    function testFuzz_buy_withWallet(uint256 purchaseAmount) public {
        purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, CAP);

        uint256 purchasePrice = purchaseAmount * SALE_RATE / MULTIPLIER;

        paymentToken.mint(ALICE, purchasePrice);

        vm.startPrank(ALICE);
        paymentToken.approve(address(dfp), purchasePrice);
        dfp.buy(purchaseAmount, BOB);

        assertEq(dfp.balanceOf(BOB), purchaseAmount);
        assertEq(paymentToken.balanceOf(WALLET), purchasePrice);
    }

    // endregion

    // region - withdraw

    function test_withdraw_success() public {
        MockERC20Dec6 mockErc20 = new MockERC20Dec6("Mock Token", "MK");
        mockErc20.mint(address(dfp), VALUE);

        assertEq(mockErc20.balanceOf(address(dfp)), VALUE);

        vm.prank(OWNER);
        dfp.withdraw(mockErc20, ALICE, VALUE);

        assertEq(mockErc20.balanceOf(address(dfp)), 0);
        assertEq(mockErc20.balanceOf(ALICE), VALUE);
    }

    function test_withdraw_dfp_success() public {
        vm.prank(OWNER);
        dfp.withdraw(dfp, ALICE, VALUE);

        assertEq(dfp.balanceOf(ALICE), VALUE);
        assertEq(dfp.balanceOf(address(dfp)), dfp.totalSupply() - VALUE);
    }

    function test_withdraw_emit_Transfer() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(dfp), ALICE, VALUE);

        vm.prank(OWNER);
        dfp.withdraw(dfp, ALICE, VALUE);
    }

    function test_withdraw_revert_ifNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(HACKER);
        dfp.withdraw(dfp, HACKER, VALUE);
    }

    // endregion

    // region - Permit

    // region - Permit. Successful approval

    function test_permit_successful() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        assertEq(dfp.allowance(ALICE, BOB), VALUE);
        assertEq(dfp.nonces(ALICE), 1);
    }

    function test_permit_emit_Approval() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.expectEmit(true, true, true, true);
        emit Approval(ALICE, BOB, VALUE);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    // endregion

    // region - Permit. Reverted transactions

    function test_permit_revert_ifExpiredPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: dfp.nonces(ALICE),
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.warp(block.timestamp + 1 days + 1 seconds); // fast forward one second past the deadline

        vm.expectRevert("ERC20Permit: expired deadline");
        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function test_permit_revert_ifInvalidSignature() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: dfp.nonces(ALICE),
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        // spender signs owner's approval
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xB0B, digest);

        vm.expectRevert("ERC20Permit: invalid signature");
        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function test_permit_revert_ifInvalidNonce() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: 1, // owner nonce stored on-chain is 0
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.expectRevert("ERC20Permit: invalid signature");
        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    function test_permit_revert_ifSignatureReplay() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.expectRevert("ERC20Permit: invalid signature");
        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }

    // endregion

    // region - Permit. Limited and unlimited permission

    function test_permit_transferFromLimitedPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: VALUE,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(address(dfp));
        dfp.transfer(ALICE, VALUE);

        vm.prank(BOB);
        dfp.transferFrom(ALICE, BOB, VALUE);

        assertEq(dfp.balanceOf(ALICE), 0);
        assertEq(dfp.balanceOf(BOB), VALUE);
        assertEq(dfp.allowance(ALICE, BOB), 0);
    }

    function test_permit_transferFromMaxPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: type(uint256).max,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(address(dfp));
        dfp.transfer(ALICE, VALUE);

        vm.prank(BOB);
        dfp.transferFrom(ALICE, BOB, VALUE);

        assertEq(dfp.balanceOf(ALICE), 0);
        assertEq(dfp.balanceOf(BOB), VALUE);
        assertEq(dfp.allowance(ALICE, BOB), type(uint256).max);
    }

    // endregion

    // region - Permit. Failure transactions

    function testFail_permit_ifInvalidAllowance() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: 5e17, // approve only 0.5 tokens
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(BOB);
        dfp.transferFrom(ALICE, BOB, VALUE); // attempt to transfer 1 token
    }

    function testFail_permit_ifInvalidBalance() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: BOB,
            value: 2e18, // approve 2 tokens
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        dfp.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        vm.prank(address(dfp));
        dfp.transfer(ALICE, VALUE);

        vm.prank(BOB);
        dfp.transferFrom(ALICE, BOB, 2e18); // attempt to transfer 2 tokens (owner only owns 1)
    }

    // endregion

    // region - Permit. Calling from another contract

    function test_permit_depositWithLimitedPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: address(deposit),
            value: VALUE,
            nonce: dfp.nonces(ALICE),
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.prank(address(dfp));
        dfp.transfer(ALICE, VALUE);

        deposit.depositWithPermit(
            address(dfp),
            VALUE,
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(dfp.balanceOf(ALICE), 0);
        assertEq(dfp.balanceOf(address(deposit)), VALUE);

        assertEq(dfp.allowance(ALICE, address(deposit)), 0);
        assertEq(dfp.nonces(ALICE), 1);

        assertEq(deposit.userDeposits(ALICE, address(dfp)), VALUE);
    }

    function test_permit_depositWithMaxPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: ALICE,
            spender: address(deposit),
            value: type(uint256).max,
            nonce: dfp.nonces(ALICE),
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.prank(address(dfp));
        dfp.transfer(ALICE, VALUE);

        deposit.depositWithPermit(
            address(dfp),
            VALUE,
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(dfp.balanceOf(ALICE), 0);
        assertEq(dfp.balanceOf(address(deposit)), VALUE);

        assertEq(dfp.allowance(ALICE, address(deposit)), type(uint256).max);
        assertEq(dfp.nonces(ALICE), 1);

        assertEq(deposit.userDeposits(ALICE, address(dfp)), VALUE);
    }

    // endregion

    // endregion
}
