// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../src/interface/option/IOptionToken.sol";

import "../BaseClarityMarkets.t.sol";

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
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);
        vm.stopPrank();

        assertEq(clarity.optionType(optionTokenId), IOptionToken.OptionType.CALL, "option type");
    }

    function test_optionType_whenPut() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);
        vm.stopPrank();

        assertEq(clarity.optionType(optionTokenId), IOptionToken.OptionType.PUT, "option type");
    }

    /////////
    // function exerciseStyle(uint256 optionTokenId) external view returns (ExerciseStyle exerciseStyle);

    function test_exerciseStyle_whenAmerican() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);
        vm.stopPrank();
        
        assertEq(clarity.exerciseStyle(optionTokenId), IOptionToken.ExerciseStyle.AMERICAN, "exercise style");
    }

    function test_exerciseStyle_whenEuropean() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), europeanExWeeklies[0], 1700e18, 0);
        vm.stopPrank();
        
        assertEq(clarity.exerciseStyle(optionTokenId), IOptionToken.ExerciseStyle.EUROPEAN, "exercise style");
    }
}
