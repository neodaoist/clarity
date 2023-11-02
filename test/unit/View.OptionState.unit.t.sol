// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Views Under Test
import {IOptionState} from "../../src/interface/option/IOptionState.sol";

contract OptionStateViewsTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function openInterest(uint256 optionTokenId) external view returns (uint64 amount);

    function test_openInterest_whenWritten() public withSimpleBackground {
        assertEq(clarity.openInterest(oti1), 2.5e6, "open interest");
    }

    function test_openInterest_whenExercised() public withSimpleBackground {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        assertEq(clarity.openInterest(oti1), 2.3e6, "open interest");
    }

    // Sad Paths

    // TODO

    /////////
    // function remainingWriteableAmount(uint256 optionTokenId)
    //     external
    //     view
    //     returns (uint64 amount);

    // TODO

    // Sad Paths

    // TODO
}
