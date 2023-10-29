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

    /// @notice Sablier V2 Lockup contract for handling payment logic
    ISablierV2LockupLinear internal immutable sablier;

    constructor(ISablierV2LockupLinear _sablier) {
        sablier = _sablier;
    }

    // EXTERNAL FUNCTIONS

    /// @inheritdoc IVesting
    function createVestingStream(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId) {
        params.asset.safeTransferFrom(msg.sender, address(this), params.totalAmount);
        params.asset.safeApprove(address(sablier), params.totalAmount);
        streamId = sablier.createWithRange(params);
    }

    /// @inheritdoc IVesting
    function withdraw(address recipient, uint256 streamId, uint128 amount) external {
        sablier.withdraw({ streamId: streamId, to: recipient, amount: amount });
    }

    /// @inheritdoc IVesting
    function withdrawMax(address recipient, uint256 streamId) external {
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
        sablier.withdrawMultiple({ streamIds: streamIds, to: recipient, amounts: amounts });
    }

    /// @inheritdoc IVesting
    function cancel(uint256 streamId) external {
        sablier.cancel(streamId);
    }

    /// @inheritdoc IVesting
    function cancelMultiple(uint256[] calldata streamIds) external {
        sablier.cancelMultiple(streamIds);
    }

    /// @inheritdoc IVesting
    function renounce(uint256 streamId) external {
        sablier.renounce(streamId);
    }

    /// @inheritdoc IVesting
    function withdrawMaxAndTransfer(address newOwner, uint256 streamId) external {
        sablier.withdrawMaxAndTransfer({ streamId: streamId, newRecipient: newOwner});
    }
    
    /// @inheritdoc IVesting
    function transferFrom(address newOwner, uint256 streamId) external {
        sablier.transferFrom({ from: address(this), to: newOwner, tokenId: streamId });
    }

    /// @inheritdoc IVesting
    function getStreamOwner(uint256 streamId) external view returns (address) {
        return sablier.getSender(streamId);
    }
}