// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Views Under Test
import {IOption} from "../../src/interface/option/IOption.sol";

contract OptionTokenViewsTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function optionTokenId(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strikePrice,
    //     bool isCall
    // ) external view returns (uint256 optionTokenId);

    // TODO

    /////////
    // function option(uint256 optionTokenId) external view returns (Option memory
    // option);

    // TODO

    // TODO convert to option() tests

    // function test_optionType_whenCall() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
    //     );
    //     vm.stopPrank();

    //     assertEq(
    //         clarity.optionType(optionTokenId), IOption.OptionType.CALL, "option type"
    //     );
    // }

    // function test_optionType_whenPut() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writePut(
    //         address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
    //     );
    //     vm.stopPrank();

    //     assertEq(
    //         clarity.optionType(optionTokenId), IOption.OptionType.PUT, "option type"
    //     );
    // }

    // function test_exerciseStyle_whenAmerican() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
    //     );
    //     vm.stopPrank();

    //     assertEq(
    //         clarity.exerciseStyle(optionTokenId),
    //         IOption.ExerciseStyle.AMERICAN,
    //         "exercise style"
    //     );
    // }

    // function test_exerciseStyle_whenEuropean() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(LUSDLIKE), europeanExWeeklies[0], 1700e18, 0
    //     );
    //     vm.stopPrank();

    //     assertEq(
    //         clarity.exerciseStyle(optionTokenId),
    //         IOption.ExerciseStyle.EUROPEAN,
    //         "exercise style"
    //     );
    // }

    /////////
    // function tokenType(uint256 tokenId) external view returns (TokenType _tokenType);

    // function test_positionTokenType() public {
    //     vm.startPrank(writer);
    //     uint256 optionTokenId =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[0], 1750e18, 0);
    //     vm.stopPrank();

    //     assertEq(
    //         X,
    //         IPosition.PositionTokenType.LONG,
    //         "positionTokenType when long"
    //     );
    //     assertEq(
    //         Y,
    //         IPosition.PositionTokenType.SHORT,
    //         "positionTokenType when short"
    //     );
    //     assertEq(
    //         Z,
    //         IPosition.PositionTokenType.ASSIGNED_SHORT,
    //         "positionTokenType when assigned short"
    //     );
    // }

    function testRevert_position_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOption.OptionType.CALL
        );
        uint256 notCreatedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, notCreatedOptionTokenId
            )
        );

        clarity.tokenType(notCreatedOptionTokenId);
    }

    function testRevert_position_whenOptionExistsButInvalidTokenType() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 0
        );
        vm.stopPrank();

        vm.expectRevert(stdError.enumConversionError);

        clarity.tokenType(optionTokenId | 3);
    }
}
