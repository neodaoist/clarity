// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// External Test Helpers
import {StdAssertions} from 'forge-std/StdAssertions.sol';

// Libraries
import {LibPosition} from "../../src/library/LibPosition.sol";

// Interfaces
import {IOption} from "../../src/interface/option/IOption.sol";
import {IPosition} from "../../src/interface/IPosition.sol";

// Contracts
import {ClarityMarkets} from "../../src/ClarityMarkets.sol";

contract Assertions is StdAssertions {
    /////////

    using LibPosition for uint256;

    ///////// Custom Multi Assertions

    function assertTotalSupplies(
        ClarityMarkets clarity,
        uint256 optionTokenId,
        uint256 expectedLong,
        uint256 expectedShort,
        uint256 expectedAssigned,
        string memory message
    ) internal {
        assertEq(
            clarity.totalSupply(optionTokenId),
            expectedLong,
            string.concat("long total supply ", message)
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToShort()),
            expectedShort,
            string.concat("short total supply ", message)
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToAssignedShort()),
            expectedAssigned,
            string.concat("assigned short total supply ", message)
        );
    }

    function assertOptionBalances(
        ClarityMarkets clarity,
        address addr,
        uint256 optionTokenId,
        uint256 expectedLong,
        uint256 expectedShort,
        uint256 expectedAssigned,
        string memory message
    ) internal {
        assertEq(
            clarity.balanceOf(addr, optionTokenId),
            expectedLong,
            string.concat("long balance ", message)
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToShort()),
            expectedShort,
            string.concat("short balance ", message)
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToAssignedShort()),
            expectedAssigned,
            string.concat("assigned short balance ", message)
        );
    }

    function assertAssetBalance(
        IERC20 asset,
        address addr,
        uint256 expectedBalance,
        string memory message
    ) internal {
        assertEq(
            asset.balanceOf(addr),
            expectedBalance,
            string.concat(asset.symbol(), " balance ", message)
        );
    }

    ///////// Custom Type Assertions

    function assertEq(IOption.Option memory a, IOption.Option memory b) internal {
        assertEq(a.baseAsset, b.baseAsset);
        assertEq(a.quoteAsset, b.quoteAsset);
        assertEq(a.expiry, b.expiry);
        assertEq(a.strike, b.strike);
        assertEq(a.optionType, b.optionType);
        assertEq(a.exerciseStyle, b.exerciseStyle);
    }

    function assertEq(IOption.Option memory a, IOption.Option memory b, string memory err)
        internal
    {
        assertEq(a.baseAsset, b.baseAsset, err);
        assertEq(a.quoteAsset, b.quoteAsset, err);
        assertEq(a.expiry, b.expiry);
        assertEq(a.strike, b.strike, err);
        assertEq(a.optionType, b.optionType, err);
        assertEq(a.exerciseStyle, b.exerciseStyle, err);
    }

    function assertEq(IOption.OptionType a, IOption.OptionType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [OptionType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOption.OptionType a, IOption.OptionType b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOption.ExerciseStyle a, IOption.ExerciseStyle b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [ExerciseStyle]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOption.ExerciseStyle a, IOption.ExerciseStyle b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IPosition.TokenType a, IPosition.TokenType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [TokenType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IPosition.TokenType a, IPosition.TokenType b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
}
