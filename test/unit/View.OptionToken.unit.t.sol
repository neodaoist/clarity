// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Views Under Test
import {IOptionToken} from "../../src/interface/option/IOptionToken.sol";

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
    // function option(uint256 optionTokenId) external view returns (Option memory option);

    // TODO

    /////////
    // function optionType(uint256 optionTokenId) external view returns (OptionType optionType);

    function test_optionType_whenCall() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        vm.stopPrank();

        assertEq(
            clarity.optionType(optionTokenId), IOptionToken.OptionType.CALL, "option type"
        );
    }

    function test_optionType_whenPut() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        vm.stopPrank();

        assertEq(
            clarity.optionType(optionTokenId), IOptionToken.OptionType.PUT, "option type"
        );
    }

    /////////
    // function exerciseStyle(uint256 optionTokenId) external view returns (ExerciseStyle exerciseStyle);

    function test_exerciseStyle_whenAmerican() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        vm.stopPrank();

        assertEq(
            clarity.exerciseStyle(optionTokenId),
            IOptionToken.ExerciseStyle.AMERICAN,
            "exercise style"
        );
    }

    function test_exerciseStyle_whenEuropean() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), europeanExWeeklies[0], 1700e18, 0
        );
        vm.stopPrank();

        assertEq(
            clarity.exerciseStyle(optionTokenId),
            IOptionToken.ExerciseStyle.EUROPEAN,
            "exercise style"
        );
    }

    /////////
    // function tokenType(uint256 tokenId) external view returns (PositionTokenType positionTokenType);

    // function test_positionTokenType() public {
    //     vm.startPrank(writer);
    //     uint256 optionTokenId =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 0);
    //     vm.stopPrank();

    //     assertEq(
    //         X,
    //         IOptionPosition.PositionTokenType.LONG,
    //         "positionTokenType when long"
    //     );
    //     assertEq(
    //         Y,
    //         IOptionPosition.PositionTokenType.SHORT,
    //         "positionTokenType when short"
    //     );
    //     assertEq(
    //         Z,
    //         IOptionPosition.PositionTokenType.ASSIGNED_SHORT,
    //         "positionTokenType when assigned short"
    //     );
    // }

    function testRevert_position_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOptionToken.OptionType.CALL
        );
        uint256 notCreatedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionDoesNotExist.selector, notCreatedOptionTokenId
            )
        );

        clarity.tokenType(notCreatedOptionTokenId);
    }

    function testRevert_position_whenOptionExistsButInvalidPositionTokenType() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 0
        );
        vm.stopPrank();

        vm.expectRevert(stdError.enumConversionError);

        clarity.tokenType(optionTokenId | 3);
    }
}
