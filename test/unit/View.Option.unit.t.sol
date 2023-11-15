// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Libraries
import {LibOption} from "../../src/library/LibOption.sol";
import {LibPosition} from "../../src/library/LibPosition.sol";

// Views Under Test
import {IOption} from "../../src/interface/option/IOption.sol";

contract OptionViewsTest is BaseClarityMarketsTest {
    /////////

    using LibPosition for uint248;
    using LibPosition for uint256;

    /////////
    // function optionTokenId(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strikePrice,
    //     bool isCall
    // ) external view returns (uint256 optionTokenId);

    // TODO

    // Sad Paths

    function testRevert_optionTokenId_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOption.OptionType.CALL
        ).hashToId();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        // When
        clarity.optionTokenId(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, true
        );
    }

    /////////
    // function option(uint256 optionTokenId) external view returns (Option memory
    // option);

    // TODO

    // Sad Paths

    function testRevert_option_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOption.OptionType.CALL
        ).hashToId();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        // When
        clarity.option(optionTokenId);
    }
}
