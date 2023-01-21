// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract TokenURI_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should return an empty string.
    function test_TokenURI_StreamNull() external {
        uint256 nullStreamId = 1729;
        string memory actualTokenURI = lockup.tokenURI({ tokenId: nullStreamId });
        string memory expectedTokenURI = string("");
        assertEq(actualTokenURI, expectedTokenURI, "tokenURI");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return an empty string.
    function test_TokenURI() external {
        uint256 streamId = createDefaultStream();
        string memory actualTokenURI = lockup.tokenURI({ tokenId: streamId });
        string memory expectedTokenURI = string("");
        assertEq(actualTokenURI, expectedTokenURI, "tokenURI");
    }
}
