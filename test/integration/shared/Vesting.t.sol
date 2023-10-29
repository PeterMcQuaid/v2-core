// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test, console } from "forge-std/Test.sol";
import { Vesting, Lockup, LockupLinear } from "../../../src/Vesting.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Base_Test } from "../../Base.t.sol";
import { MAX_UD60x18, UD60x18, ud, Casting } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";
import { LockupLinear_Integration_Fuzz_Test } from "../fuzz/lockup-linear/LockupLinear.t.sol";

contract Vesting_Test is Base_Test {
    Vesting internal vesting;

    event VestingStreamCreated(address indexed streamOwner, uint256 streamId);
    event StreamOwnerChanged(address indexed oldOwner, address indexed newOwner, uint256 streamId);
    event StreamCanceled(address indexed owner, uint256 streamId);

    error SablierV2Lockup_WithdrawAmountZero(uint256 streamId);
    error SablierV2Lockup_StreamNotCancelable(uint256 streamId);
    error SablierV2Lockup_StreamSettled(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Base_Test.setUp();

        // Deploy V2 Core.
        deployCoreConditionally();

        // Make the Admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve V2 Core to spend assets from the users.
        approveProtocol();
        vm.stopPrank();

        vesting = new Vesting(lockupLinear);
    }

    function createStream() internal returns (uint256 streamId) {
        uint40 start = uint40(block.timestamp);
        uint40 cliff = uint40(block.timestamp + 5 days);
        uint40 end = uint40(block.timestamp + 50 days);
        LockupLinear.CreateWithRange memory params;
        params.sender = address(vesting);
        params.recipient = users.alice;
        params.totalAmount = uint128(1000);
        params.asset = dai;
        params.cancelable = false;
        params.transferable = true;
        params.range = LockupLinear.Range(start, cliff, end);
        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);
        params.broker.account = users.broker;
        streamId = vesting.createVestingStream(params);
    }

    function test_createVestingStream() external {
        uint256 aliceBalanceBefore = dai.balanceOf(address(users.alice));
        uint256 lockupLinearBalanceBefore = dai.balanceOf(address(lockupLinear));
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        createStream();
        vm.stopPrank();
        assertEq(aliceBalanceBefore - dai.balanceOf(address(users.alice)), dai.balanceOf(address(lockupLinear)) - lockupLinearBalanceBefore);
    }

    function test_createVestingStreamEmit() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        vm.expectEmit(true, false, false, true, address(vesting));
        emit VestingStreamCreated(users.alice, 1);
        createStream();
        vm.stopPrank();
    }

    function test_Withdraw() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(6 days);
        uint256 aliceBalanceBefore = dai.balanceOf(address(users.alice));
        uint256 lockupLinearBalanceBefore = dai.balanceOf(address(lockupLinear));
        vm.startPrank(users.alice);
        vesting.withdrawMax(users.alice, streamId);
        vm.stopPrank();
        assertEq(dai.balanceOf(address(users.alice)) - aliceBalanceBefore, lockupLinearBalanceBefore - dai.balanceOf(address(lockupLinear)));
    }

    function test_WithdrawTooEarlyRevert() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(1 days);
        vm.startPrank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(SablierV2Lockup_WithdrawAmountZero.selector, 1));
        vesting.withdrawMax(users.alice, streamId);
        vm.stopPrank();
    }

    function testFuzz_Withdraw(uint256 withdrawTime) external {
        withdrawTime = bound(withdrawTime, 5 days, 50 days);
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(withdrawTime);
        vm.startPrank(users.alice);
        vesting.withdrawMax(users.alice, streamId);
        vm.stopPrank();
    }

    function test_CancelBeforeSettledRevert() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(10 days);
        vm.startPrank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(SablierV2Lockup_StreamNotCancelable.selector, streamId));
        vesting.cancel(streamId);
        vm.stopPrank();
    }

    function test_CancelAfterSettledRevert() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(60 days);
        vm.startPrank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(SablierV2Lockup_StreamSettled.selector, streamId));
        vesting.cancel(streamId);
        vm.stopPrank();
    }
    
    function test_transferFromEmit() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(6 days);
        vm.startPrank(users.alice);
        lockupLinear.approve(address(vesting), streamId);
        vm.expectEmit(true, true, false, true, address(vesting));
        emit StreamOwnerChanged(users.alice, users.eve, streamId);
        vesting.transferFrom(users.eve, streamId);
        vm.stopPrank();
    }

    function test_transferFromNotAuthorizedRevert() external {
        vm.startPrank(users.alice);
        dai.approve(address(vesting), uint128(1000));
        uint256 streamId = createStream();
        vm.stopPrank();
        skip(6 days);
        vm.startPrank(users.eve);
        vm.expectRevert("Sender must be stream owner");
        vesting.transferFrom(users.eve, streamId);
        vm.stopPrank();
    }
}