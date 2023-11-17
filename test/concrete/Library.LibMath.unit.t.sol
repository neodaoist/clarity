// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Library Under test
import {LibMath} from "../../src/library/LibMath.sol";

contract LibMathTest is Test {
    /////////

    ///////// Clearing Unit Conversion

    function test_oneClearingUnit() public {
        assertEq(
            LibMath.oneClearingUnit(18), 1e12, "oneClearingUnit should return 1e-6 less"
        );
    }

    ///////// Strike Price Conversions

    function test_actualScaledDownToClearingStrikeUnit() public {
        assertEq(
            LibMath.actualScaledDownToClearingStrikeUnit(42.000001e18),
            42.000001e12,
            "actualScaledDownToClearingStrikeUnit should return 1e-6 less"
        );
    }

    function test_clearingScaledUpToActualStrike() public {
        assertEq(
            LibMath.clearingScaledUpToActualStrike(42.000001e12),
            42.000001e18,
            "clearingScaledUpToActualStrike should return 1e6 more"
        );
    }

    function test_actualScaledDownToHumanReadableStrike() public {
        assertEq(
            LibMath.actualScaledDownToHumanReadableStrike(42e18, 18),
            42,
            "actualScaledDownToHumanReadableStrike should return no decimal precision"
        );
    }

    function test_clearingScaledDownToHumanReadableStrike() public {
        assertEq(
            LibMath.clearingScaledDownToHumanReadableStrike(42e12, 18),
            42,
            "clearingScaledDownToHumanReadableStrike should return no decimal precision"
        );
    }
}
