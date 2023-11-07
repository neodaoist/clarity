// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract MetadataTest is BaseClarityMarketsTest {
    /////////

    function test_tokenURI() public {
        string memory tokenURI = clarity.tokenURI(1);

        console2.log(tokenURI);
    }
}
