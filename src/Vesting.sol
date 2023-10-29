// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { IVesting } from "./interfaces/IVesting.sol";
import {
    ISablierV2LockupLinear, 
    ISablierV2Lockup,
    Lockup,
    LockupLinear
    } from "./SablierV2LockupLinear.sol";
import { IERC20 } from "./types/Tokens.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title An ERC-20 vesting contract using Sablier V2 for payment logic
 * @author Peter Raymond McQuaid
 * @notice See the documentation in {IVesting} 
 */
contract Vesting is IVesting {
    using SafeERC20 for IERC20;

    /// @notice streamId => streamOwner
    mapping(uint256 streamId => address) internal streamOwner;

    /// @notice Sablier V2 Lockup contract for handling payment logic
    ISablierV2LockupLinear internal immutable sablier;

    modifier onlySteamOwner(uint256 streamId) {
        require(msg.sender == streamOwner[streamId], "Sender must be stream owner");
        _;
    }

    constructor(ISablierV2LockupLinear _sablier) {
        sablier = _sablier;
    }

    // EXTERNAL FUNCTIONS

    /// @inheritdoc IVesting
    function createVestingStream(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId) {
        require(params.sender == address(this), "Vesting.createVestingStream: Sender must be this contract");
        params.asset.safeTransferFrom(msg.sender, address(this), params.totalAmount);
        params.asset.safeApprove(address(sablier), params.totalAmount);
        streamId = sablier.createWithRange(params);
        streamOwner[streamId] = msg.sender;
        emit VestingStreamCreated(msg.sender, streamId);
    }

    /// @inheritdoc IVesting
    function withdraw(address recipient, uint256 streamId, uint128 amount) external onlySteamOwner(streamId) {
        sablier.withdraw({ streamId: streamId, to: recipient, amount: amount });
    }

    /// @inheritdoc IVesting
    function withdrawMax(address recipient, uint256 streamId) external onlySteamOwner(streamId) {
        sablier.withdrawMax({ streamId: streamId, to: recipient });
    }

    /// @inheritdoc IVesting
    function withdrawMultiple(
        address recipient,
        uint256[] calldata streamIds, 
        uint128[] calldata amounts
    ) 
        external 
    {
        for (uint256 i = 0; i < streamIds.length;) {
            require(msg.sender == streamOwner[streamIds[i]], "Sender must be stream owner");
            unchecked {
                ++i;
            }
        }
        sablier.withdrawMultiple({ streamIds: streamIds, to: recipient, amounts: amounts });
    }

    /// @inheritdoc IVesting
    function cancel(uint256 streamId) external onlySteamOwner(streamId) {
        sablier.cancel(streamId);
        address oldOwner = streamOwner[streamId];
        streamOwner[streamId] = address(0);
        emit StreamCanceled(oldOwner, streamId);
    }

    /// @inheritdoc IVesting
    function cancelMultiple(uint256[] calldata streamIds) external {
         for (uint256 i = 0; i < streamIds.length;) {
            require(msg.sender == streamOwner[streamIds[i]], "Sender must be stream owner");
            unchecked {
                ++i;
            }
        }
        sablier.cancelMultiple(streamIds);
        address oldOwner = streamOwner[streamIds[0]];
        for (uint256 i = 0; i < streamIds.length;) {
            streamOwner[streamIds[i]] = address(0);
            unchecked {
                ++i;
            }
            emit StreamCanceled(oldOwner, streamIds[i]);
        }
    }

    /// @inheritdoc IVesting
    function renounce(uint256 streamId) external onlySteamOwner(streamId) {
        sablier.renounce(streamId);
    }

    /// @inheritdoc IVesting
    function withdrawMaxAndTransfer(address newOwner, uint256 streamId) external onlySteamOwner(streamId) {
        sablier.withdrawMaxAndTransfer({ streamId: streamId, newRecipient: newOwner});
        address oldOwner = streamOwner[streamId];
        streamOwner[streamId] = newOwner;
        emit StreamOwnerChanged(oldOwner, newOwner, streamId);
    }
    
    /// @inheritdoc IVesting
    function transferFrom(address newOwner, uint256 streamId) external onlySteamOwner(streamId) {
        sablier.transferFrom({ from: msg.sender, to: newOwner, tokenId: streamId });
        address oldOwner = streamOwner[streamId];
        streamOwner[streamId] = newOwner;
        emit StreamOwnerChanged(oldOwner, newOwner, streamId);
    }

    /// @inheritdoc IVesting
    function getStreamOwner(uint256 streamId) external view returns (address) {
        return streamOwner[streamId];
    }
}