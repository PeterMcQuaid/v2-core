// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract ClaimProtocolRevenues_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IAdminable.Adminable_CallerNotAdmin.selector, users.admin, users.eve));
        sablierV2.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolRevenuesZero() external callerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_NoProtocolRevenues.selector, DEFAULT_ASSET));
        sablierV2.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier protocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank(users.sender);
        createDefaultStream();
        changePrank(users.admin);
        _;
    }

    /// @dev it should claim the protocol revenues, update the protocol revenues, and emit a {ClaimProtocolRevenues}
    /// event.
    function test_ClaimProtocolRevenues() external callerAdmin protocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.admin, protocolRevenues)));

        // Expect a {ClaimProtocolRevenues} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ClaimProtocolRevenues(users.admin, DEFAULT_ASSET, protocolRevenues);

        // Claim the protocol revenues.
        sablierV2.claimProtocolRevenues(DEFAULT_ASSET);

        // Assert that the protocol revenues were set to zero.
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
