// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Fuzz_Test } from "../../Fuzz.t.sol";
import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        createDefaultStreams();
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenArrayCountNotZero() {
        _;
    }

    modifier whenNoNull() {
        _;
    }

    modifier whenNoStatusSettled() {
        _;
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
        createDefaultStreams();
        changePrank({ msgSender: users.recipient });
        _;
    }

    modifier whenAllStreamsCancelable() {
        _;
    }

    /// @dev TODO: mark this test as `external` once Foundry reverts this breaking change:
    /// https://github.com/foundry-rs/foundry/pull/4845#issuecomment-1529125648
    function testFuzz_CancelMultiple(
        uint256 timeWarp,
        uint40 endTime
    )
        private
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenNoStatusSettled
        whenCallerAuthorizedAllStreams
        whenAllStreamsCancelable
    {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION - 1);
        endTime = boundUint40(endTime, DEFAULT_END_TIME, DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION);

        // Create a new stream with a different end time.
        uint256 streamId = createDefaultStreamWithEndTime(endTime);

        // Simulate the passage of time.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(streamIds[0]);
        expectCallToTransfer({ to: users.sender, amount: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(streamIds[1]);
        expectCallToTransfer({ to: users.sender, amount: senderAmount1 });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: streamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount0,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: streamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount1,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount1
        });

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams have been updated.
        Lockup.Status expectedStatus0 =
            senderAmount0 == DEFAULT_DEPOSIT_AMOUNT ? Lockup.Status.DEPLETED : Lockup.Status.CANCELED;
        Lockup.Status expectedStatus1 =
            senderAmount1 == DEFAULT_DEPOSIT_AMOUNT ? Lockup.Status.DEPLETED : Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(streamIds[0]), expectedStatus0, "status0");
        assertEq(lockup.statusOf(streamIds[1]), expectedStatus1, "status1");

        // Assert that the streams are not cancelable anymore.
        assertFalse(lockup.isCancelable(streamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(streamIds[1]), "isCancelable1");

        // Assert that the refunded amounts have been updated.
        uint128 expectedReturnedAmount0 = senderAmount0;
        uint128 expectedReturnedAmount1 = senderAmount1;
        assertEq(lockup.getRefundedAmount(streamIds[0]), expectedReturnedAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(streamIds[1]), expectedReturnedAmount1, "refundedAmount1");

        // Assert that the NFTs have not been burned.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(streamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), expectedNFTOwner, "NFT owner1");
    }

    /// @dev Creates the default streams used throughout the tests.
    function createDefaultStreams() internal {
        defaultStreamIds = new uint256[](2);
        defaultStreamIds[0] = createDefaultStream();
        defaultStreamIds[1] = createDefaultStream();
    }
}
