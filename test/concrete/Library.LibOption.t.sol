// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

// Library Under test
import {LibOption} from "../../src/library/LibOption.sol";

contract LibOptionTest is BaseUnitTestSuite {
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

    ///////// String Conversion for...
    
    // Exercise Style

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

    // Strike Price

    function test_strike_toString() public {
        assertEq(LibOption.toString(1750), "1750", "toString(1750) should return '1750'");
    }

    // Unix Timestamp

    function test_unixTimestamp_toString() public {
        assertEq(
            LibOption.toString(1_699_825_363),
            "1699825363",
            "toString(1625097600) should return '1699825363'"
        );
    }
}
