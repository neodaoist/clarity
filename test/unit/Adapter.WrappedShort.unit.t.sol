// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Interfaces
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

contract AdapterTest is BaseClarityMarketsTest {
    /////////

    using LibToken for uint256;

    ClarityERC20Factory internal factory;
    ClarityWrappedShort internal wrappedShort;

    function setUp() public override {
        super.setUp();

        // deploy factory
        factory = new ClarityERC20Factory(clarity);
    }

    // TODO
}
