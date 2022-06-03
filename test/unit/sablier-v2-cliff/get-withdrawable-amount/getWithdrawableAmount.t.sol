// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__GetWithdrawableAmount__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need one.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(nonStreamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the cliff time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external {
        vm.warp(stream.cliffTime - 1 seconds);
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the cliff time is equal to the block timestamp, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(stream.cliffTime);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT - bn(100);
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been no withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals() external {
        vm.warp(stream.startTime + TIME_OFFSET);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals() external {
        vm.warp(stream.startTime + TIME_OFFSET);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }
}
