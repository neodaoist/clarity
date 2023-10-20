// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {ClarityMarkets} from "../src/ClarityMarkets.sol";

contract ClarityMarketsTest is Test {
    ClarityMarkets public markets;

    function setUp() public {
        markets = new ClarityMarkets();
    }

    function test_true() public {
        assertTrue(true);
    }
}
