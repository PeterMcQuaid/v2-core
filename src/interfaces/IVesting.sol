// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {
    ISablierV2LockupLinear, 
    ISablierV2Lockup,
    Lockup,
    LockupLinear
    } from "../SablierV2LockupLinear.sol";
import { IERC20 } from "../types/Tokens.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title An ERC-20 vesting contract interface using Sablier V2 for payment logic
 * @author Peter Raymond McQuaid
 * @notice The key functionalities are:
 * - Creates and manages multiple vesting streams using Sablier V2 Lockup contracts
 * - Can handle multiple vesting streams for a single owner
 * - Can handle multiple ERC-20 tokens
 * - Allows cancellation, withdrawal, and ownership transfer of vesting streams
 * @dev This interface assumes utilization of the "createWithRange" linear function
 * of the Sablier V2 Lockup contract, rather than "createWithDurations",
 * as the former gives more flexability in the vesting schedule
 * @dev All stream owner checks are completed in Sablier V2 Lockup contract
 */
interface IVesting {

    // EXTERNAL FUNCTIONS

    /// @notice Creates a vesting stream using Sablier V2 Lockup contract
    function createVestingStream(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId);

    /**
     * @notice Withdraws tokens from vesting stream
     * @param recipient Address to withdraw tokens to
     * @param streamId StreamId of stream to withdraw from
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(address recipient, uint256 streamId, uint128 amount) external;

    /**
     * @notice Withdraws max tokens from vesting stream
     * @param recipient Address to withdraw tokens to
     * @param streamId StreamId of stream to withdraw from
     */
    function withdrawMax(address recipient, uint256 streamId) external;

    /**
     * @notice Withdraws tokens from multiple vesting streams atomically
     * @param recipient Address to withdraw tokens to
     * @param streamIds StreamIds of streams to withdraw from
     * @param amounts Amount of tokens to withdraw
     */
    function withdrawMultiple(address recipient, uint256[] calldata streamIds, uint128[] calldata amounts) external;

    /**
     * @notice Cancels a given vesting stream
     * @param streamId StreamId of stream to cancel 
     */
    function cancel(uint256 streamId) external;

    /**
     * @notice Cancels multiple vesting streams atomically
     * @param streamIds StreamIds of streams to cancel 
     */
    function cancelMultiple(uint256[] calldata streamIds) external;

    /**
     * @notice Owner of vesting stream can renounce ownership
     * @param streamId StreamId of stream to renounce 
     */
    function renounce(uint256 streamId) external;

    /**
     * @notice Withdraws max tokens from vesting stream and changes owner
     * @param newOwner Address to change ownership to
     * @param streamId StreamId of stream to withdraw from and transfer ownership
     */
    function withdrawMaxAndTransfer(address newOwner, uint256 streamId) external;
    
    /**
     * @notice Changes ownership of given stream
     * @param newOwner Address to change ownership to
     * @param streamId StreamId of stream to transfer ownership from
     */
    function transferFrom(address newOwner, uint256 streamId) external;

    /**
     * @dev Explicit getter function for streamId to owner mapping. This getter is not
     * necessary as the Sablier V2 Lockup contract has a getter for this mapping, but
     * is included in this interface for clarity
     */
    function getStreamOwner(uint256 streamId) external view returns (address);
}