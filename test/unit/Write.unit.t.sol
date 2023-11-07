// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract WriteTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function writeCall(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strikePrice,
    //     uint64 optionAmount
    // ) external returns (uint256 optionTokenId);

    function test_writeCall() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({ // TODO update elsewhere
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            1e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_zero() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // no change
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            0,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
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
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        oti1 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.0275e6
        );
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(oti1);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(oti1)),
            0.0275e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(oti1)),
            0,
            "assigned balance"
        );
        assertEq(
            WETHLIKE.balanceOf(writer),
            wethBalance - 0.0275e18,
            "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 17e6
        );

        // check option exists
        option = clarity.option(oti2);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1750e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 17e18, "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[1], 1700e18, 1e6
        );

        // check option exists
        option = clarity.option(oti3);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: FRI1 + 1 seconds,
                expiryTimestamp: FRI2
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writeCall(
            address(WBTCLIKE), address(LUSDLIKE), americanExWeeklies[0], 20_000e18, 10e6
        );
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti4);
        assertEq(option.baseAsset, address(WBTCLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 20_000e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(
            WBTCLIKE.balanceOf(writer), wbtcBalance - 10e8, "WBTC balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        oti5 = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1800e6, 1e6
        );

        // check option exists
        option = clarity.option(oti5);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(USDCLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1800e6, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.CALL, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write"
        );
        assertEq(USDCLIKE.balanceOf(writer), usdcBalance, "USDC balance after write");

        // check previous option balances did not change
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance final");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(oti1)),
            0.0275e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(oti1)),
            0,
            "assigned balance"
        );
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
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeCall(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            (2 ** 64 - 1) * 1e6,
            1e6
        );
        vm.stopPrank();
    }

    // TODO valid but almost expired
    // TODO add totalSupply() checks

    // Events

    function testEvent_writeCall_OptionCreated() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.CALL
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOptionToken.OptionType.CALL
        );

        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
        vm.stopPrank();
    }

    function testEvent_writeCall_OptionsWritten() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.CALL
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.005e6
        );
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writeCall_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(WETHLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writeCall_whenExerciseWindowMispaired() public {
        vm.expectRevert(OptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), mispaired, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowZeroTime() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN
            )
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), misordered, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN - 2 days;
        zeroTime[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writeCall_whenStrikePriceTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.StrikePriceTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1e6 - 1, 1e6
        );
    }

    function testRevert_writeCall_whenStrikePriceTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.StrikePriceTooLarge.selector, ((2 ** 64 - 1) * 1e6) + 1
            )
        );

        vm.prank(writer);
        clarity.writeCall(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            ((2 ** 64 - 1) * 1e6) + 1,
            1e6
        );
    }

    function testRevert_writeCall_whenGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, tooMuch
        );
        vm.stopPrank();
    }

    // TODO double check all relevant reverts covered for writePut(), write(), and batchWrite()
    // TODO revert when trying to write too small an amount (1e-6 - 1)
    // TODO insufficient asset balance
    // TODO insufficient asset approval

    /////////
    // function writePut(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindow,
    //     uint256 strikePrice,
    //     uint64 optionAmount
    // ) external returns (uint256 _optionTokenId);

    function test_writePut() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            1e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
    }

    function test_writePut_zero() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        // check option exists
        IOptionToken.Option memory option = clarity.option(optionTokenId);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // no change
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            0,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
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
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        oti1 = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.0275e6
        );
        vm.stopPrank();

        // check option exists
        IOptionToken.Option memory option = clarity.option(oti1);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(oti1)),
            0.0275e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(oti1)),
            0,
            "assigned balance"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1700e18 * 0.0275),
            "LUSD balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 17e6
        );

        // check option exists
        option = clarity.option(oti2);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1750e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1750e18 * 17),
            "LUSD balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[1], 1700e18, 1e6
        );

        // check option exists
        option = clarity.option(oti3);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: FRI1 + 1 seconds,
                expiryTimestamp: FRI2
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1700e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(
            LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writePut(
            address(WBTCLIKE), address(LUSDLIKE), americanExWeeklies[0], 20_000e18, 10e6
        );
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti4);
        assertEq(option.baseAsset, address(WBTCLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(LUSDLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 20_000e18, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (20_000e18 * 10),
            "LUSD balance after write"
        );
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance, "WBTC balance after write");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        oti5 = clarity.writePut(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1800e6, 1e6
        );
        vm.stopPrank();

        // check option exists
        option = clarity.option(oti5);
        assertEq(option.baseAsset, address(WETHLIKE), "option stored baseAsset");
        assertEq(option.quoteAsset, address(USDCLIKE), "option stored quoteAsset");
        assertEq(
            option.exerciseWindow,
            IOptionToken.ExerciseWindow({
                exerciseTimestamp: DAWN + 1 seconds,
                expiryTimestamp: FRI1
            }),
            "option stored exerciseWindows"
        );
        assertEq(option.strikePrice, 1800e6, "option stored strikePrice");
        assertEq(
            option.optionType, IOptionToken.OptionType.PUT, "option stored optionType"
        );
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "option stored exerciseStyle"
        );

        // check balances
        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(
            USDCLIKE.balanceOf(writer), usdcBalance - 1800e6, "USDC balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // check previous option balances did not change
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance final");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(oti1)),
            0.0275e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(oti1)),
            0,
            "assigned balance"
        );
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
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 1_000_000_000)); // need moar LUSD to write put with massive strike
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1_000_000_000));
        clarity.writePut(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            (2 ** 64 - 1) * 1e6,
            1e6
        );
        vm.stopPrank();
    }

    // Events

    function testEvent_writePut_OptionCreated() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.PUT
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOptionToken.OptionType.CALL
        );

        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
        vm.stopPrank();
    }

    function testEvent_writePut_OptionsWritten() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.PUT
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0.005e6
        );
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writePut_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(WETHLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6
        );
    }

    function testRevert_writePut_whenExerciseWindowMispaired() public {
        vm.expectRevert(OptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), mispaired, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowZeroTime() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN
            )
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), misordered, 1700e18, 1e6);
    }

    function testRevert_writePut_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN - 2 days;
        zeroTime[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writePut(address(WETHLIKE), address(LUSDLIKE), zeroTime, 1700e18, 1e6);
    }

    function testRevert_writePut_whenStrikePriceTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.StrikePriceTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1e6 - 1, 1e6
        );
    }

    function testRevert_writePut_whenStrikePriceTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.StrikePriceTooLarge.selector, ((2 ** 64 - 1) * 1e6) + 1
            )
        );

        vm.prank(writer);
        clarity.writePut(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            ((2 ** 64 - 1) * 1e6) + 1,
            1e6
        );
    }

    function testRevert_writePut_whenGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, tooMuch
        );
        vm.stopPrank();
    }

    /////////
    // function write(uint256 optionTokenId, uint64 optionAmount) external

    function test_write_whenCall() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 1.25e6);
        vm.stopPrank();

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1.25e6, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            1.25e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
        assertEq(
            WETHLIKE.balanceOf(writer),
            wethBalance - (1e18 * 1.25),
            "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_write_whenPut() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 1.35e6);
        vm.stopPrank();

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1.35e6, "long balance");
        assertEq(
            clarity.balanceOf(writer, LibToken.longToShort(optionTokenId)),
            1.35e6,
            "short balance"
        );
        assertEq(
            clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenId)),
            0,
            "assigned balance"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1700e18 * 1.35),
            "LUSD balance after write"
        );
    }

    // Events

    function testEvent_write_whenCall_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.CALL
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.write(optionTokenId, 0.005e6);
        vm.stopPrank();
    }

    function testEvent_write_whenPut_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            IOptionToken.OptionType.PUT
        );
        uint256 expectedOptionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.006e6);

        clarity.write(optionTokenId, 0.006e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_write_whenWriteAmountZero() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        vm.expectRevert(OptionErrors.WriteAmountZero.selector);

        clarity.write(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_write_whenInitialAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.write(optionTokenId, tooMuch);
        vm.stopPrank();
    }

    function testRevert_write_whenSubsequentAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 10e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.WriteAmountTooLarge.selector, tooMuch - 10e6
            )
        );

        clarity.write(optionTokenId, tooMuch - 10e6);
        vm.stopPrank();
    }

    function testRevert_write_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOptionToken.OptionType.CALL
        );
        uint256 optionTokenId = LibToken.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        vm.prank(writer);
        clarity.write(optionTokenId, 1e6);
    }

    function testRevert_write_whenOptionExpired() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionExpired.selector,
                optionTokenId,
                americanExWeeklies[0][1]
            )
        );

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        clarity.write(optionTokenId, 1e6);
        vm.stopPrank();
    }

    /////////
    // function batchWrite(uint256[] calldata optionTokenIds, uint64[] calldata optionAmounts) external

    function test_batchWrite() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 1.25e6;

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        clarity.batchWrite(optionTokenIds, optionAmounts);
        vm.stopPrank();

        // check balances
        assertEq(clarity.balanceOf(writer, optionTokenIds[0]), 1.25e6, "long balance");
        assertEq(
            clarity.balanceOf(writer, optionTokenIds[0] + 1), 1.25e6, "short balance"
        );
        assertEq(clarity.balanceOf(writer, optionTokenIds[0] + 2), 0, "assigned balance");
        assertEq(
            WETHLIKE.balanceOf(writer),
            wethBalance - (1e18 * 1.25),
            "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    // TODO update to match new max asset amounts

    // function test_batchWrite_many() public {
    //     uint256 wethBalance = WETHLIKE.balanceOf(writer);
    //     uint256 wbtcBalance = WBTCLIKE.balanceOf(writer);
    //     uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
    //     uint256 usdcBalance = USDCLIKE.balanceOf(writer);

    //     vm.startPrank(writer);
    //     uint256[] memory optionTokenIds = new uint256[](8);
    //     optionTokenIds[0] =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);
    //     optionTokenIds[1] =
    //         clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0);
    //     optionTokenIds[2] =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1725e18, 0);
    //     optionTokenIds[3] =
    //         clarity.writePut(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1725e18, 0);
    //     optionTokenIds[4] =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[3], 1700e18, 0);
    //     optionTokenIds[5] =
    //         clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1675e6, 0);
    //     optionTokenIds[6] =
    //         clarity.writeCall(address(WBTCLIKE), address(LUSDLIKE), americanExWeeklies[1], 21_001e18, 0);
    //     optionTokenIds[7] =
    //         clarity.writePut(address(WBTCLIKE), address(USDCLIKE), americanExWeeklies[1], 21_001e6, 0);
    //     uint64[] memory optionAmounts = new uint64[](8);
    //     optionAmounts[0] = 1.25e6;
    //     optionAmounts[1] = 0.000001e6;
    //     optionAmounts[2] = 1.35e6;
    //     optionAmounts[3] = 0.5e6;
    //     optionAmounts[4] = 1e6;
    //     optionAmounts[5] = 1_000e6;
    //     optionAmounts[6] = 1.222222e6;
    //     optionAmounts[7] = 0.999999e6;

    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
    //     LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
    //     USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));

    //     clarity.batchWrite(optionTokenIds, optionAmounts);
    //     vm.stopPrank();

    //     // check Clarity balances
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[0]), optionAmounts[0], "long balance 1");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[0])), optionAmounts[0], "short balance 1");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[0])), 0, "assigned balance 1");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[1]), optionAmounts[1], "long balance 2");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[1])), optionAmounts[1], "short balance 2");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[1])), 0, "assigned balance 2");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[2]), optionAmounts[2], "long balance 3");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[2])), optionAmounts[2], "short balance 3");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[2])), 0, "assigned balance 3");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[3]), optionAmounts[3], "long balance 4");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[3])), optionAmounts[3], "short balance 4");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[3])), 0, "assigned balance 4");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[4]), optionAmounts[4], "long balance 5");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[4])), optionAmounts[4], "short balance 5");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[4])), 0, "assigned balance 5");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[5]), optionAmounts[5], "long balance 6");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[5])), optionAmounts[5], "short balance 6");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[5])), 0, "assigned balance 6");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[6]), optionAmounts[6], "long balance 7");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[6])), optionAmounts[6], "short balance 7");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[6])), 0, "assigned balance 7");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[7]), optionAmounts[7], "long balance 8");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToShort(optionTokenIds[7])), optionAmounts[7], "short balance 8");
    //     assertEq(clarity.balanceOf(writer, LibToken.longToAssignedShort(optionTokenIds[7])), 0, "assigned balance 8");

    //     // check ERC20 balances
    //     // console2.log("--- WETH");
    //     // console2.log(wethBalance);
    //     // console2.log(scaleDownOptionAmount(1e18) * optionAmounts[0]);
    //     // console2.log(scaleDownOptionAmount(1e18) * optionAmounts[2]);
    //     // console2.log(scaleDownOptionAmount(1e18) * optionAmounts[4]);
    //     // console2.log(scaleDownOptionAmount(1e18) * optionAmounts[5]);
    //     // console2.log("--- WBTC");
    //     // console2.log(wbtcBalance);
    //     // console2.log(scaleDownOptionAmount(1e8) * optionAmounts[6]);
    //     // console2.log("--- LUSD");
    //     // console2.log(lusdBalance);
    //     // console2.log(scaleDownOptionAmount(1700e18) * optionAmounts[1]);
    //     // console2.log(scaleDownOptionAmount(1725e18) * optionAmounts[3]);
    //     // console2.log("--- USDC");
    //     // console2.log(usdcBalance);
    //     // console2.log(scaleDownOptionAmount(21_001e6) * optionAmounts[7]);
    //     uint256 expectedWethBalance = wethBalance - (scaleDownOptionAmount(1e18) * optionAmounts[0])
    //         - (scaleDownOptionAmount(1e18) * optionAmounts[2]) - (scaleDownOptionAmount(1e18) * optionAmounts[4])
    //         - (scaleDownOptionAmount(1e18) * optionAmounts[5]);
    //     uint256 expectedWbtcBalance = wbtcBalance - (scaleDownOptionAmount(1e8) * optionAmounts[6]);
    //     uint256 expectedLusdBalance = lusdBalance - (scaleDownOptionAmount(1700e18) * optionAmounts[1])
    //         - (scaleDownOptionAmount(1725e18) * optionAmounts[3]);
    //     uint256 expectedUsdcBalance = usdcBalance - (scaleDownOptionAmount(21_001e6) * optionAmounts[7]);
    //     assertEq(WETHLIKE.balanceOf(writer), expectedWethBalance, "WETH balance after write");
    //     assertEq(WBTCLIKE.balanceOf(writer), expectedWbtcBalance, "WBTC balance after write");
    //     assertEq(LUSDLIKE.balanceOf(writer), expectedLusdBalance, "LUSD balance after write");
    //     assertEq(USDCLIKE.balanceOf(writer), expectedUsdcBalance, "USDC balance after write");
    // }

    // TODO check events in above test

    // Sad Paths

    function testRevert_batchWrite_whenArrayLengthZero() public {
        vm.expectRevert(OptionErrors.BatchWriteArrayLengthZero.selector);

        uint256[] memory optionTokenIds = new uint256[](0);
        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 123e6;

        vm.prank(writer);
        clarity.batchWrite(optionTokenIds, optionAmounts);
    }

    function testRevert_batchWrite_whenArrayLengthMismatch() public {
        vm.expectRevert(OptionErrors.BatchWriteArrayLengthMismatch.selector);

        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = 213;
        uint64[] memory optionAmounts = new uint64[](2);
        optionAmounts[0] = 456e6;
        optionAmounts[1] = 789e6;

        vm.prank(writer);
        clarity.batchWrite(optionTokenIds, optionAmounts);
    }

    // TODO add more batchWrite() tests for write() sad paths (eg, option expired, write amount zero)
}
