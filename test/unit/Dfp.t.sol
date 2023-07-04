// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20Dec6} from "test/mock/MockERC20Dec6.sol";
import {DepositMock} from "test/mock/DepositMock.sol";
import {SigUtils} from "test/utils/SigUtils.sol";
import {DFP} from "src/Dfp.sol";

contract DfpTest is Test {
    DFP public dfp;
    DepositMock internal deposit;
    MockERC20Dec6 internal mockErc20dec6;
    SigUtils internal sigUtils;

    address internal ALICE = vm.addr(0xA11CE);
    address internal BOB = vm.addr(0xB0B);
    address internal OWNER = vm.addr(0xA);
    address internal WALLET = vm.addr(0xB);
    address internal HACKER = vm.addr(0xEBA);

    uint256 internal constant CAP = 100_000_000e18;
    uint256 internal constant VALUE = 1e18;
    uint256 internal constant DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // region - Set Up

    function setUp() public {
        vm.label(ALICE, "ALICE");
        vm.label(BOB, "BOB");
        vm.label(OWNER, "Owner");
        vm.label(WALLET, "Wallet");
        vm.label(HACKER, "Hacker");

        mockErc20dec6 = new MockERC20Dec6("Mock Token", "MK");
        deposit = new DepositMock();

        vm.prank(OWNER);
        dfp = new DFP(mockErc20dec6, WALLET);

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
        assertEq(mockErc20.balanceOf(ALICE), VALUE);
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
        dfp.transfer(ALICE, 1e18);

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
