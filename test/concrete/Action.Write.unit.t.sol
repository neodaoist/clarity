// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

contract WriteTest is BaseUnitTestSuite {
    /////////

    using LibOption for uint32[];    

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
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // check balances
        assertTotalSupplies(optionTokenId, 1e6, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 1e6, 1e6, 0, "option balances");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_zero() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // no change
        assertTotalSupplies(optionTokenId, 0, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "option balances");
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
        oti1 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0.0275e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti1), expected, "option 1 stored");

        // check balances
        assertTotalSupplies(oti1, 0.0275e6, 0, "total supplies 1");
        assertOptionBalances(writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 balances");
        assertEq(
            WETHLIKE.balanceOf(writer),
            wethBalance - 0.0275e18,
            "WETH balance after write 1"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write 1");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1750e18,
            optionAmount: 17e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1750e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti2), expected, "option 2 stored");

        // check balances
        assertTotalSupplies(oti2, 17e6, 0, "total supplies 2");
        assertOptionBalances(writer, oti2, 17e6, 17e6, 0, "option 2 balances");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 17e18, "WETH balance after write 2"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write 2");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[1],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[1].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti3), expected, "option 3 stored");

        // check balances
        assertTotalSupplies(oti3, 1e6, 0, "total supplies 3");
        assertOptionBalances(writer, oti3, 1e6, 1e6, 0, "option 3 balances");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write 3"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write 3");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writeCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 20_000e18,
            optionAmount: 10e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 20_000e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti4), expected, "option 4 stored");

        // check balances
        assertTotalSupplies(oti4, 10e6, 0, "total supplies 4");
        assertOptionBalances(writer, oti4, 10e6, 10e6, 0, "option 4 balances");
        assertEq(
            WBTCLIKE.balanceOf(writer), wbtcBalance - 10e8, "WBTC balance after write 4"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write 4");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        oti5 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1800e6,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1800e6,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti5), expected, "option 5 stored");

        // check balances
        assertTotalSupplies(oti5, 1e6, 0, "total supplies 5");
        assertOptionBalances(writer, oti5, 1e6, 1e6, 0, "option 5 balances");
        assertEq(
            WETHLIKE.balanceOf(writer), wethBalance - 1e18, "WETH balance after write 5"
        );
        assertEq(USDCLIKE.balanceOf(writer), usdcBalance, "USDC balance after write 5");

        // check previous option balances did not change
        assertOptionBalances(writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 final balances");
        assertOptionBalances(writer, oti2, 17e6, 17e6, 0, "option 2 final balances");
        assertOptionBalances(writer, oti3, 1e6, 1e6, 0, "option 3 final balances");
        assertOptionBalances(writer, oti4, 10e6, 10e6, 0, "option 4 final balances");
    }

    function test_writeCall_whenLargeButValidStrikePrice() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        // no revert
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: (2 ** 64 - 1) * 1e6,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    // TODO valid but almost expired
    // TODO add totalSupply() checks

    // Events

    function testEvent_writeCall_OptionCreated() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOption.OptionType.CALL
        );

        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function testEvent_writeCall_OptionsWritten() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0.005e6
        });
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writeCall_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(WETHLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenExerciseWindowMispaired() public {
        vm.expectRevert(IOptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: mispaired,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenExerciseWindowZeroTime() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: zeroTime,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN
            )
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: misordered,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days
            )
        );

        uint32[] memory expiryPast = new uint32[](2);
        expiryPast[0] = DAWN - 2 days;
        expiryPast[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: expiryPast,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenStrikePriceTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikePriceTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1e6 - 1,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenStrikePriceTooLarge() public {
        uint256 tooLarge = ((2 ** 64 - 1) * 1e6) + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.StrikePriceTooLarge.selector, tooLarge
            )
        );

        vm.prank(writer);
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: tooLarge,
            optionAmount: 1e6
        });
    }

    function testRevert_writeCall_whenAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: tooMuch
        });
        vm.stopPrank();
    }

    // TODO double check all relevant reverts covered for writePut(), write(), and
    // batchWrite()
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
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // check balances
        assertTotalSupplies(optionTokenId, 1e6, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 1e6, 1e6, 0, "option balances");
        assertEq(
            LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
    }

    function test_writePut_zero() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // no change
        assertTotalSupplies(optionTokenId, 0, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "option balances");
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
        oti1 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0.0275e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti1), expected, "option 1 stored");

        // check balances
        assertTotalSupplies(oti1, 0.0275e6, 0, "total supplies 1");
        assertOptionBalances(writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 balances");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1700e18 * 0.0275),
            "LUSD balance after write 1"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write 1");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1750e18,
            optionAmount: 17e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1750e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti2), expected, "option 2 stored");

        // check balances
        assertTotalSupplies(oti2, 17e6, 0, "total supplies 2");
        assertOptionBalances(writer, oti2, 17e6, 17e6, 0, "option 2 balances");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1750e18 * 17),
            "LUSD balance after write 2"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write 2");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[1],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[1].toExerciseWindow(),
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti3), expected, "option 3 stored");

        // check balances
        assertTotalSupplies(oti3, 1e6, 0, "total supplies 3");
        assertOptionBalances(writer, oti3, 1e6, 1e6, 0, "option 3 balances");
        assertEq(
            LUSDLIKE.balanceOf(writer), lusdBalance - 1700e18, "LUSD balance after write 3"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write 3");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writePut({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 20_000e18,
            optionAmount: 10e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 20_000e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti4), expected, "option 4 stored");

        // check balances
        assertTotalSupplies(oti4, 10e6, 0, "total supplies 4");
        assertOptionBalances(writer, oti4, 10e6, 10e6, 0, "option 4 balances");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (20_000e18 * 10),
            "LUSD balance after write 4"
        );
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance, "WBTC balance after write 4");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        oti5 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1800e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0].toExerciseWindow(),
            strikePrice: 1800e6,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti5), expected, "option 5 stored");

        // check balances
        assertTotalSupplies(oti5, 1e6, 0, "total supplies 5");
        assertOptionBalances(writer, oti5, 1e6, 1e6, 0, "option 5 balances");
        assertEq(
            USDCLIKE.balanceOf(writer), usdcBalance - 1800e6, "USDC balance after write"
        );
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");

        // check previous option balances did not change
        assertOptionBalances(writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 final balances");
        assertOptionBalances(writer, oti2, 17e6, 17e6, 0, "option 2 final balances");
        assertOptionBalances(writer, oti3, 1e6, 1e6, 0, "option 3 final balances");
        assertOptionBalances(writer, oti4, 10e6, 10e6, 0, "option 4 final balances");
    }

    function test_writePut_whenLargeButValidStrikePrice() public {
        // need moar LUSD to write put with massive strike
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 1_000_000_000));

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1_000_000_000));
        // no revert
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: (2 ** 64 - 1) * 1e6,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    // Events

    function testEvent_writePut_OptionCreated() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0][0],
            americanExWeeklies[0][1],
            1700e18,
            IOption.OptionType.CALL
        );

        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function testEvent_writePut_OptionsWritten() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0.005e6
        });
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writePut_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(WETHLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 5
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 5
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(5)
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenBaseAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(WETHLIKE), 19
            )
        );

        vm.mockCall(
            address(WETHLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenQuoteAssetDecimalsTooLarge() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetDecimalsOutOfRange.selector, address(LUSDLIKE), 19
            )
        );

        vm.mockCall(
            address(LUSDLIKE),
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(19)
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenExerciseWindowMispaired() public {
        vm.expectRevert(IOptionErrors.ExerciseWindowMispaired.selector);

        uint32[] memory mispaired = new uint32[](1);
        mispaired[0] = DAWN;

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: mispaired,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenExerciseWindowZeroTime() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowZeroTime.selector, DAWN, DAWN
            )
        );

        uint32[] memory zeroTime = new uint32[](2);
        zeroTime[0] = DAWN;
        zeroTime[1] = DAWN;

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: zeroTime,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenExerciseWindowMisordered() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowMisordered.selector, DAWN + 1 seconds, DAWN
            )
        );

        uint32[] memory misordered = new uint32[](2);
        misordered[0] = DAWN + 1 seconds;
        misordered[1] = DAWN;

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: misordered,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenExerciseWindowExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseWindowExpiryPast.selector, DAWN - 1 days
            )
        );

        uint32[] memory expiryPast = new uint32[](2);
        expiryPast[0] = DAWN - 2 days;
        expiryPast[1] = DAWN - 1 days;

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: expiryPast,
            strikePrice: 1700e18,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenStrikePriceTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikePriceTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1e6 - 1,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenStrikePriceTooLarge() public {
        uint256 tooLarge = ((2 ** 64 - 1) * 1e6) + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.StrikePriceTooLarge.selector, tooLarge
            )
        );

        vm.prank(writer);
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: tooLarge,
            optionAmount: 1e6
        });
    }

    function testRevert_writePut_whenAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );
        
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: tooMuch
        });
        vm.stopPrank();
    }

    /////////
    // function write(uint256 optionTokenId, uint64 optionAmount) external

    function test_write_givenCall() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 1.25e6);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(optionTokenId, 1.25e6, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 1.25e6, 1.25e6, 0, "option balances");
        assertEq(
            WETHLIKE.balanceOf(writer),
            wethBalance - (1e18 * 1.25),
            "WETH balance after write"
        );
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_write_givenPut() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 1.35e6);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(optionTokenId, 1.35e6, 0, "total supplies");
        assertOptionBalances(writer, optionTokenId, 1.35e6, 1.35e6, 0, "option balances");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
        assertEq(
            LUSDLIKE.balanceOf(writer),
            lusdBalance - (1700e18 * 1.35),
            "LUSD balance after write"
        );
    }

    // Events

    function testEvent_write_givenCall_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.write(optionTokenId, 0.005e6);
        vm.stopPrank();
    }

    function testEvent_write_givenPut_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.006e6);

        clarity.write(optionTokenId, 0.006e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_write_givenCall_whenWriteAmountZero() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        vm.expectRevert(IOptionErrors.WriteAmountZero.selector);

        clarity.write(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_write_givenCall_whenInitialAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.write(optionTokenId, tooMuch);
        vm.stopPrank();
    }

    function testRevert_write_givenCall_whenSubsequentAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 10e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.WriteAmountTooLarge.selector, tooMuch - 10e6
            )
        );

        clarity.write(optionTokenId, tooMuch - 10e6);
        vm.stopPrank();
    }

    function testRevert_write_givenCall_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL
        });
        uint256 optionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        vm.prank(writer);
        clarity.write(optionTokenId, 1e6);
    }

    function testRevert_write_givenCall_whenOptionExpired() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector,
                optionTokenId,
                americanExWeeklies[0][1]
            )
        );

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        clarity.write(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_write_givenPut_whenWriteAmountZero() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        vm.expectRevert(IOptionErrors.WriteAmountZero.selector);

        clarity.write(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_write_givenPut_whenInitialAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, tooMuch)
        );

        clarity.write(optionTokenId, tooMuch);
        vm.stopPrank();
    }

    function testRevert_write_givenPut_whenSubsequentAmountGreaterThanMaximumWritable() public {
        uint64 tooMuch = clarity.MAXIMUM_WRITABLE() + 1;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 10e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.WriteAmountTooLarge.selector, tooMuch - 10e6
            )
        );

        clarity.write(optionTokenId, tooMuch - 10e6);
        vm.stopPrank();
    }

    function testRevert_write_givenPut_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.PUT
        });
        uint256 optionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        vm.prank(writer);
        clarity.write(optionTokenId, 1e6);
    }

    function testRevert_write_givenPut_whenOptionExpired() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector,
                optionTokenId,
                americanExWeeklies[0][1]
            )
        );

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        clarity.write(optionTokenId, 1e6);
        vm.stopPrank();
    }

    /////////
    // function batchWrite(uint256[] calldata optionTokenIds, uint64[] calldata
    // optionAmounts) external

    function test_batchWrite() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 0
        });
        
        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 1.25e6;

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        clarity.batchWrite(optionTokenIds, optionAmounts);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(optionTokenIds[0], 1.25e6, 0, "total supplies");
        assertOptionBalances(writer, optionTokenIds[0], 1.25e6, 1.25e6, 0, "option balances");
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
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[0], 1700e18, 0);
    //     optionTokenIds[1] =
    //         clarity.writePut(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[0], 1700e18, 0);
    //     optionTokenIds[2] =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[0], 1725e18, 0);
    //     optionTokenIds[3] =
    //         clarity.writePut(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[0], 1725e18, 0);
    //     optionTokenIds[4] =
    //         clarity.writeCall(address(WETHLIKE), address(LUSDLIKE),
    // americanExWeeklies[3], 1700e18, 0);
    //     optionTokenIds[5] =
    //         clarity.writeCall(address(WETHLIKE), address(USDCLIKE),
    // americanExWeeklies[0], 1675e6, 0);
    //     optionTokenIds[6] =
    //         clarity.writeCall(address(WBTCLIKE), address(LUSDLIKE),
    // americanExWeeklies[1], 21_001e18, 0);
    //     optionTokenIds[7] =
    //         clarity.writePut(address(WBTCLIKE), address(USDCLIKE),
    // americanExWeeklies[1], 21_001e6, 0);
    //     uint64[] memory optionAmounts = new uint64[](8);
    //     optionAmounts[0] = 1.25e6;
    //     optionAmounts[1] = 0.000001e6;
    //     optionAmounts[2] = 1.35e6;
    //     optionAmounts[3] = 0.5e6;
    //     optionAmounts[4] = 1e6;
    //     optionAmounts[5] = 1_000e6;
    //     optionAmounts[6] = 1.222222e6;
    //     optionAmounts[7] = 0.999999e6;

    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE,
    // STARTING_BALANCE));
    //     LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE,
    // STARTING_BALANCE));
    //     USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE,
    // STARTING_BALANCE));

    //     clarity.batchWrite(optionTokenIds, optionAmounts);
    //     vm.stopPrank();

    //     // check Clarity balances
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[0]), optionAmounts[0], "long
    // balance 1");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[0])),
    // optionAmounts[0], "short balance 1");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[0])), 0, "assigned balance 1");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[1]), optionAmounts[1], "long
    // balance 2");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[1])),
    // optionAmounts[1], "short balance 2");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[1])), 0, "assigned balance 2");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[2]), optionAmounts[2], "long
    // balance 3");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[2])),
    // optionAmounts[2], "short balance 3");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[2])), 0, "assigned balance 3");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[3]), optionAmounts[3], "long
    // balance 4");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[3])),
    // optionAmounts[3], "short balance 4");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[3])), 0, "assigned balance 4");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[4]), optionAmounts[4], "long
    // balance 5");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[4])),
    // optionAmounts[4], "short balance 5");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[4])), 0, "assigned balance 5");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[5]), optionAmounts[5], "long
    // balance 6");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[5])),
    // optionAmounts[5], "short balance 6");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[5])), 0, "assigned balance 6");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[6]), optionAmounts[6], "long
    // balance 7");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[6])),
    // optionAmounts[6], "short balance 7");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[6])), 0, "assigned balance 7");
    //     assertEq(clarity.balanceOf(writer, optionTokenIds[7]), optionAmounts[7], "long
    // balance 8");
    //     assertEq(clarity.balanceOf(writer, LibPosition.longToShort(optionTokenIds[7])),
    // optionAmounts[7], "short balance 8");
    //     assertEq(clarity.balanceOf(writer,
    // LibPosition.longToAssignedShort(optionTokenIds[7])), 0, "assigned balance 8");

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
    //     uint256 expectedWethBalance = wethBalance - (scaleDownOptionAmount(1e18) *
    // optionAmounts[0])
    //         - (scaleDownOptionAmount(1e18) * optionAmounts[2]) -
    // (scaleDownOptionAmount(1e18) * optionAmounts[4])
    //         - (scaleDownOptionAmount(1e18) * optionAmounts[5]);
    //     uint256 expectedWbtcBalance = wbtcBalance - (scaleDownOptionAmount(1e8) *
    // optionAmounts[6]);
    //     uint256 expectedLusdBalance = lusdBalance - (scaleDownOptionAmount(1700e18) *
    // optionAmounts[1])
    //         - (scaleDownOptionAmount(1725e18) * optionAmounts[3]);
    //     uint256 expectedUsdcBalance = usdcBalance - (scaleDownOptionAmount(21_001e6) *
    // optionAmounts[7]);
    //     assertEq(WETHLIKE.balanceOf(writer), expectedWethBalance, "WETH balance after
    // write");
    //     assertEq(WBTCLIKE.balanceOf(writer), expectedWbtcBalance, "WBTC balance after
    // write");
    //     assertEq(LUSDLIKE.balanceOf(writer), expectedLusdBalance, "LUSD balance after
    // write");
    //     assertEq(USDCLIKE.balanceOf(writer), expectedUsdcBalance, "USDC balance after
    // write");
    // }

    // Events

    // TODO

    // Sad Paths

    function testRevert_batchWrite_whenArrayLengthZero() public {
        vm.expectRevert(IOptionErrors.BatchWriteArrayLengthZero.selector);

        uint256[] memory optionTokenIds = new uint256[](0);
        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 123e6;

        vm.prank(writer);
        clarity.batchWrite(optionTokenIds, optionAmounts);
    }

    function testRevert_batchWrite_whenArrayLengthMismatch() public {
        vm.expectRevert(IOptionErrors.BatchWriteArrayLengthMismatch.selector);

        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = 213;
        uint64[] memory optionAmounts = new uint64[](2);
        optionAmounts[0] = 456e6;
        optionAmounts[1] = 789e6;

        vm.prank(writer);
        clarity.batchWrite(optionTokenIds, optionAmounts);
    }

    // TODO add more batchWrite() sad paths (eg, option expired, write amount zero)
}
