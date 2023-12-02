// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Test Helpers
import {Assertions} from "./util/Assertions.sol";

// Contracts
import "../src/ClarityMarkets.sol";

abstract contract BaseTestSuite is Test, Assertions {
    /////////

    // Contract Under Test
    ClarityMarkets internal clarity;

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
