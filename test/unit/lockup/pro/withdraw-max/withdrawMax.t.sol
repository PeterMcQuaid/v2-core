// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Unit_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { WithdrawMax_Unit_Test } from "test/unit/lockup/shared/withdraw-max/withdrawMax.t.sol";

contract WithdrawMax_Pro_Unit_Test is Pro_Unit_Test, WithdrawMax_Unit_Test {
    function setUp() public virtual override(Pro_Unit_Test, WithdrawMax_Unit_Test) {
        WithdrawMax_Unit_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
