// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract ClarityMarketsInvariantTest is Test {
    /////////

    ClarityMarkets private clarity;

    function setUp() public {
        clarity = new ClarityMarkets();
    }

    function invariant_sumOfAllBalancesForTokenIdEqualsTotalSupply() public {
        assertTrue(true);
    }
}
