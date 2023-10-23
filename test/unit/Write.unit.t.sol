// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract WriteTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function writeCall(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strikePrice,
    //     uint80 optionAmount
    // ) external returns (uint256 optionTokenId);

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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write");
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - 0.0275e18, "WETH balance after write");
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1750e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - 17e18, "WETH balance after write");
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: FRI1 + 1 seconds, expiryTimestamp: FRI2}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write");
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 20_000e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance - 10e8, "WBTC balance after write");
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
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1800e6, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write");
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

    function test_writeCall_whenLargeButValidStrikePrice() public {
        // no revert
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], (2 ** 64 - 1) * 1e6, 1e6
        );
        vm.stopPrank();
    }

    function testEvent_writeCall_CreateOption() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));

        vm.expectEmit(false, true, true, true); // TODO fix optionTokenId assertion
        emit CreateOption(
            123,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOptionToken.OptionType.CALL
        );

        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();
    }

    function testEvent_writeCall_WriteOptions() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));

        vm.expectEmit(true, false, true, true); // TODO fix optionTokenId assertion
        emit WriteOptions(writer, 123, 0.005e6);

        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.005e6);
        vm.stopPrank();
    }

    function testRevert_writeCall_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetsIdentical.selector, address(WETHLIKE), address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(WETHLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5)
        );

        vm.mockCall(address(WETHLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(5));

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5)
        );

        vm.mockCall(address(LUSDLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(5));

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19)
        );

        vm.mockCall(address(WETHLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(19));

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19)
        );

        vm.mockCall(address(LUSDLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(19));

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowMispaired() public {
        vm.expectRevert(OptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), mispaired, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowZeroTime() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN));

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN)
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), misordered, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days));

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN - 2 days;
        zeroTime[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenStrikePriceTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.StrikePriceTooLarge.selector, ((2 ** 64 - 1) * 1e6) + 1)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], ((2 ** 64 - 1) * 1e6) + 1, 1e6
        );
    }

    /////////
    // function writePut(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindow,
    //     uint256 strikePrice,
    //     uint80 optionAmount
    // ) external returns (uint256 _optionTokenId);

    function test_writePut() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
    }

    function test_writePut_zero() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // no change
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 0, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
    }

    function test_writePut_many() public {
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
        LUSDLIKE.approve(address(clarity), scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 oti1 =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.0275e6);
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(oti1);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance - (1700e18 * 0.0275), "LUSD balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti2 =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 17e6);

        // check option exists
        option = clarity.option(oti2);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1750e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance - (1750e18 * 17), "LUSD balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti3 =
            clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[1], 1700e18, 1e6);

        // check option exists
        option = clarity.option(oti3);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: FRI1 + 1 seconds, expiryTimestamp: FRI2}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleAssetAmount(WBTCLIKE, STARTING_BALANCE));
        uint256 oti4 =
            clarity.writePut(address(WBTCLIKE), address(LUSDLIKE), americanExWeeklies[0], 20_000e18, 10e6);
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti4);
        assertEq(option.baseAsset, address(WBTCLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 20_000e18, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance - (20_000e18 * 10), "LUSD balance after write");
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance, "WBTC balance after write");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 oti5 =
            clarity.writePut(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1800e6, 1e6);
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti5);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(USDCLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({exerciseTimestamp: DAWN + 1 seconds, expiryTimestamp: FRI1}),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1800e6, "option stored strikePrice");
        assertEq(option.optionType, IOptionToken.OptionType.PUT, "option stored optionType");
        assertEq(option.exerciseStyle, IOptionToken.ExerciseStyle.AMERICAN, "option stored exerciseStyle");

        // check balances
        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(USDCLIKE.balanceOf(writer), usdcBalance - 1800e6, "USDC balance after write");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

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

    function test_writePut_whenLargeButValidStrikePrice() public {
        // no revert
        deal(address(LUSDLIKE), writer, scaleAssetAmount(LUSDLIKE, 1_000_000_000)); // need moar LUSD to write put with massive strike
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleAssetAmount(LUSDLIKE, 1_000_000_000));
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], (2 ** 64 - 1) * 1e6, 1e6
        );
        vm.stopPrank();
    }

    function testEvent_writePut_CreateOption() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectEmit(false, true, true, true); // TODO fix optionTokenId assertion
        emit CreateOption(
            123,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOptionToken.OptionType.CALL
        );

        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();
    }

    function testEvent_writePut_WriteOptions() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectEmit(true, false, true, true); // TODO fix optionTokenId assertion
        emit WriteOptions(writer, 123, 0.005e6);

        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.005e6);
        vm.stopPrank();
    }

    function testRevert_writePut_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetsIdentical.selector, address(WETHLIKE), address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(WETHLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5)
        );

        vm.mockCall(address(WETHLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(5));

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5)
        );

        vm.mockCall(address(LUSDLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(5));

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19)
        );

        vm.mockCall(address(WETHLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(19));

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19)
        );

        vm.mockCall(address(LUSDLIKE), abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(19));

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowMispaired() public {
        vm.expectRevert(OptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), mispaired, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowZeroTime() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN));

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN)
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), misordered, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days));

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN - 2 days;
        zeroTime[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writePut_whenStrikePriceTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.StrikePriceTooLarge.selector, ((2 ** 64 - 1) * 1e6) + 1)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], ((2 ** 64 - 1) * 1e6) + 1, 1e6
        );
    }

    // TODO insufficient asset balance
    // TODO insufficient asset approval
}
