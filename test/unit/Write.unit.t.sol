// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract WriteTest is BaseClarityMarketsTest {
    /////////

    function test_writeCall() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 1e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_zero() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // no change
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 0, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_many() public {
        // write WETH-LUSD x3, WBTC-LUSD, WETH-USDC

        // standardized scalar
        // 1e18 WETH = 1 option, so 1e-6 options is 1e12 WETH
        // 1e8 WTBC = 1 option, so 1e-6 options is 1e2 WBTC
        // 1e18 LUSD = 1 option, so 1e-6 options is 1e12 LUSD
        // 1e6 USDC = 1 option, so 1e-6 options is 1 USDC

        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 wbtcBalance = WBTCLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 usdcBalance = USDCLIKE.balanceOf(writer);

        // WETH-LUSD 1
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 oti1 =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.0275e6);
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(oti1);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 0.0275e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti2 =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 17e6);

        // check option exists
        option = clarity.option(oti2);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1750e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 17e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti3 =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[1], 1700e18, 1e6);

        // check option exists
        option = clarity.option(oti3);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e18), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleAssetAmount(WBTCLIKE, STARTING_BALANCE));
        uint256 oti4 =
            clarity.writeCall(address(WBTCLIKE), address(LUSDLIKE), americanExWeeklies[0], 20_000e18, 10e6);
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti4);
        assertEq(option.baseAsset, address(WBTCLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 20_000e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance - (1e8 * 10), "WBTC balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti5 =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1800e6, 1e6);

        // check option exists
        option = clarity.option(oti5);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(USDCLIKE), "option stored quoteAsset");
        // TODO check ExerciseWindow[] exerciseWindows
        assertEq(option.strikePrice, 1800e6, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 1e6), "WETH balance after write");
        assertEq(USDCLIKE.balanceOf(writer), usdcBalance, "USDC balance after write");

        // check previous option balances did not change
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance final");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
    }
}
