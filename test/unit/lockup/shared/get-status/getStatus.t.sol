// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Status } from "src/types/Enums.sol";

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract GetStatus_Unit_Test is Shared_Lockup_Unit_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return the NULL status.
    function test_GetStatus_Null() external {
        uint256 nullStreamId = 1729;
        Status actualStatus = lockup.getStatus(nullStreamId);
        Status expectedStatus = Status.NULL;
        assertEq(actualStatus, expectedStatus);
    }

    modifier streamCreated() {
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the ACTIVE status.
    function test_GetStatus_Active() external streamCreated {
        Status actualStatus = lockup.getStatus(defaultStreamId);
        Status expectedStatus = Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);
    }

    modifier streamCanceled() {
        lockup.cancel(defaultStreamId);
        _;
    }

    /// @dev it should return the CANCELED status.
    function test_GetStatus_Canceled() external streamCreated streamCanceled {
        Status actualStatus = lockup.getStatus(defaultStreamId);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier streamDepleted() {
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        _;
    }

    /// @dev it should return the DEPLETED status.
    function test_GetStatus_Depleted() external streamCreated streamDepleted {
        Status actualStatus = lockup.getStatus(defaultStreamId);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }
}
