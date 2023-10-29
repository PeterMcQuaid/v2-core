// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test, console } from "forge-std/Test.sol";
import { Vesting, Lockup, LockupLinear } from "../../../src/Vesting.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Base_Test } from "../../Base.t.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";
import { LockupLinear_Integration_Fuzz_Test } from "../fuzz/lockup-linear/LockupLinear.t.sol";

contract Vesting_Test is Base_Test {
    Vesting internal vesting;

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

        vesting = new Vesting(lockupLinear);
    }

    function createStream(LockupLinear.CreateWithRange calldata params) internal {
        vesting.createVestingStream(params);
    }

    function test_createVestingStream() external {
        uint40 start = uint40(block.timestamp);
        uint40 cliff = uint40(block.timestamp + 5 days);
        uint40 end = uint40(block.timestamp + 50 days);

        address account = users.broker;
        //UD60x18 fee = UD60x18(1e16);

        LockupLinear.CreateWithRange memory params;
        params.sender = msg.sender;
        params.recipient = users.alice;
        params.totalAmount = 1000;
        params.asset = dai;
        params.cancelable = false;
        params.transferable = false;
        params.range = LockupLinear.Range(start, cliff, end);
        //params.broker = Broker(account, fee);
        //createStream(params);
    }
}