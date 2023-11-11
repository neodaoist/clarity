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

    ///////// Exercise Style

    // TODO

    ///////// Exercise Window

    // TODO
}
