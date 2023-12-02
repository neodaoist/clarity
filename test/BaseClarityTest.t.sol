// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Test Helpers
import {Assertions} from "./util/Assertions.sol";

// Contracts
import "../src/ClarityMarkets.sol";

abstract contract BaseClarityTest is Test, Assertions {
    /////////

    // Time
    uint32 internal constant DAWN = 1_697_788_800; // Fri Oct 20 2023 08:00:00 GMT+0000

    // Contract Under Test
    ClarityMarkets internal clarity;

    ///////// Setup

    function setUp() public virtual {
        // dawn
        vm.warp(DAWN);

        // deploy DCP
        clarity = new ClarityMarkets();
    }

    ///////// Internal State Helpers

    function getInternalOptionState(bytes32 slot)
        public
        view
        returns (uint64, uint64, uint64, uint64)
    {
        bytes32 state = vm.load(address(clarity), slot);

        return (
            uint64(uint256(state)),
            uint64(uint256(state >> 64)),
            uint64(uint256(state >> 128)),
            uint64(uint256(state >> 192))
        );
    }
}
