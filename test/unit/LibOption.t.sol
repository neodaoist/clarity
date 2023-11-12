// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Library Under test
import {LibOption} from "../../src/library/LibOption.sol";

contract LibOptionTest is BaseClarityMarketsTest {
    /////////

    ///////// Instrument Hash

    function test_paramsToHash() public {
        uint248 expectedHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint248 actualHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(USDCLIKE),
            americanExWeeklies[0],
            uint256(1750e18),
            IOption.OptionType.CALL
        );

        assertEq(actualHash, expectedHash, "paramsToHash");
    }

    ///////// Option Type

    function test_optionType_toString() public {
        assertEq(
            LibOption.toString(IOption.OptionType.CALL),
            "Call",
            "toString(CALL) should return 'Call'"
        );
        assertEq(
            LibOption.toString(IOption.OptionType.PUT),
            "Put",
            "toString(PUT) should return 'Put'"
        );
    }

    ///////// Exercise Style

    function test_determineExerciseStyle() public {
        assertEq(
            LibOption.determineExerciseStyle(americanExWeeklies[0]),
            IOption.ExerciseStyle.AMERICAN,
            "determineExerciseStyle should return AMERICAN for American-style exercise window"
        );
        assertEq(
            LibOption.determineExerciseStyle(europeanExWeeklies[0]),
            IOption.ExerciseStyle.EUROPEAN,
            "determineExerciseStyle should return EUROPEAN for European-style exercise window"
        );
    }

    function test_exerciseStyle_toString() public {
        assertEq(
            LibOption.toString(IOption.ExerciseStyle.AMERICAN),
            "American",
            "toString(AMERICAN) should return 'American'"
        );
        assertEq(
            LibOption.toString(IOption.ExerciseStyle.EUROPEAN),
            "European",
            "toString(EUROPEAN) should return 'European'"
        );
    }

    ///////// Exercise Window

    function test_toExerciseWindow() public {
        IOption.ExerciseWindow memory expectedExerciseWindow = IOption.ExerciseWindow(
            americanExWeeklies[0][0],
            americanExWeeklies[0][1]
        );
        IOption.ExerciseWindow memory actualExerciseWindow = LibOption.toExerciseWindow(
            americanExWeeklies[0]
        );

        assertEq(
            actualExerciseWindow,
            expectedExerciseWindow,
            "toExerciseWindow should return the correct ExerciseWindow"
        );
    }

    ///////// String Conversion for Strike Price and Unix Timestamp

    function test_strikePrice_toString() public {
        assertEq(
            LibOption.toString(1750),
            "1750",
            "toString(1750) should return '1750'"
        );
    }

    function test_unixTimestamp_toString() public {
        assertEq(
            LibOption.toString(1699825363),
            "1699825363",
            "toString(1625097600) should return '1699825363'"
        );
    }
}
