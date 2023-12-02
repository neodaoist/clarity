// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTestSuite.t.sol";

contract WriteTest is BaseUnitTestSuite {
    /////////

    using LibOption for uint32[];

    /////////
    // function writeNewCall(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strike,
    //     uint64 optionAmount
    // ) external returns (uint256 optionTokenId);

    function test_writeNewCall() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // check balances
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "total supplies");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1e6, 1e6, 0, "option balances"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance - 1e18, "after write");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write");
    }

    function test_writeNewCall_zero() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // no change
        assertTotalSupplies(clarity, optionTokenId, 0, 0, 0, "total supplies");
        assertOptionBalances(clarity, writer, optionTokenId, 0, 0, 0, "option balances");
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write");
    }

    function test_writeNewCall_many() public {
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
        oti1 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.0275e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti1), expected, "option 1 stored");

        // check balances
        assertTotalSupplies(clarity, oti1, 0.0275e6, 0.0275e6, 0, "total supplies 1");
        assertOptionBalances(
            clarity, writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 balances"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance - 0.0275e18, "after write 1");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write 1");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 17e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti2), expected, "option 2 stored");

        // check balances
        assertTotalSupplies(clarity, oti2, 17e6, 17e6, 0, "total supplies 2");
        assertOptionBalances(clarity, writer, oti2, 17e6, 17e6, 0, "option 2 balances");
        assertAssetBalance(WETHLIKE, writer, wethBalance - 17e18, "after write 2");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write 2");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti3), expected, "option 3 stored");

        // check balances
        assertTotalSupplies(clarity, oti3, 1e6, 1e6, 0, "total supplies 3");
        assertOptionBalances(clarity, writer, oti3, 1e6, 1e6, 0, "option 3 balances");
        assertAssetBalance(WETHLIKE, writer, wethBalance - 1e18, "after write 3");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write 3");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writeNewCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 20_000e18,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 20_000e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti4), expected, "option 4 stored");

        // check balances
        assertTotalSupplies(clarity, oti4, 10e6, 10e6, 0, "total supplies 4");
        assertOptionBalances(clarity, writer, oti4, 10e6, 10e6, 0, "option 4 balances");
        assertAssetBalance(WBTCLIKE, writer, wbtcBalance - 10e8, "after write 4");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write 4");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        oti5 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1800e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1800e6,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti5), expected, "option 5 stored");

        // check balances
        assertTotalSupplies(clarity, oti5, 1e6, 1e6, 0, "total supplies 5");
        assertOptionBalances(clarity, writer, oti5, 1e6, 1e6, 0, "option 5 balances");
        assertAssetBalance(WETHLIKE, writer, wethBalance - 1e18, "after write 5");
        assertAssetBalance(USDCLIKE, writer, usdcBalance, "after write 5");

        // check previous option balances did not change
        assertOptionBalances(
            clarity, writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti2, 17e6, 17e6, 0, "option 2 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti3, 1e6, 1e6, 0, "option 3 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti4, 10e6, 10e6, 0, "option 4 final balances"
        );
    }

    function test_writeNewCall_whenFarInFutureButValidExpiry() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        // no revert
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: uint32(clarity.MAXIMUM_EXPIRY() - 1),
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function test_writeNewCall_whenLargeButValidStrikePrice() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        // no revert
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: (2 ** 64 - 1) * 1e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function test_writeNewCall_whenAmountAtLimitOfMaximumWritable() public {
        // need moar WETH to write massive amount of calls
        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 2e18));
        // no revert
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: true,
            optionAmount: maximumAmount
        });
        vm.stopPrank();
    }

    // Events

    function testEvent_writeNewCall_OptionCreated() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1700e18,
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );

        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function testEvent_writeNewCall_OptionsWritten() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.005e6
        });
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writeNewCall_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(WETHLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenBaseAssetDecimalsTooSmall() public {
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
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenQuoteAssetDecimalsTooSmall() public {
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
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenBaseAssetDecimalsTooLarge() public {
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
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenQuoteAssetDecimalsTooLarge() public {
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
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_givenOptionAlreadyExists() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "before second write");

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionAlreadyExists.selector, optionTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.8e6
        });
    }

    function testRevert_writeNewCall_whenExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.ExpiryPast.selector, DAWN - 1 days)
        );

        vm.prank(writer);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: DAWN - 1 days,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenStrikeTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikeTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e6 - 1,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_whenStrikeTooLarge() public {
        uint256 tooLarge = ((2 ** 64 - 1) * 1e6) + 1;

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikeTooLarge.selector, tooLarge)
        );

        vm.prank(writer);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: tooLarge,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_givenInsufficientAssetBalance() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        vm.prank(brokeWriter);
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewCall_givenInsufficientAssetApproval() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);
        deal(address(WETHLIKE), scaleUpAssetAmount(WETHLIKE, 1));

        vm.startPrank(brokeWriter);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 1) - 1);

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");
        clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    /////////
    // function writeNewPut(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindow,
    //     uint256 strike,
    //     uint64 optionAmount
    // ) external returns (uint256 _optionTokenId);

    function test_writeNewPut() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // check balances
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "total supplies");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1e6, 1e6, 0, "option balances"
        );
        assertAssetBalance(LUSDLIKE, writer, lusdBalance - 1700e18, "after write");
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write");
    }

    function test_writeNewPut_zero() public {
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(optionTokenId), expected, "option stored");

        // no change
        assertTotalSupplies(clarity, optionTokenId, 0, 0, 0, "total supplies");
        assertOptionBalances(clarity, writer, optionTokenId, 0, 0, 0, "option balances");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write");
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write");
    }

    function test_writeNewPut_many() public {
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
        oti1 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.0275e6
        });
        vm.stopPrank();

        // check option exists
        IOption.Option memory expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti1), expected, "option 1 stored");

        // check balances
        assertTotalSupplies(clarity, oti1, 0.0275e6, 0.0275e6, 0, "total supplies 1");
        assertOptionBalances(
            clarity, writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 balances"
        );
        assertAssetBalance(
            LUSDLIKE, writer, lusdBalance - (1700e18 * 0.0275), "after write 1"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write 1");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti2 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 17e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti2), expected, "option 2 stored");

        // check balances
        assertTotalSupplies(clarity, oti2, 17e6, 17e6, 0, "total supplies 2");
        assertOptionBalances(clarity, writer, oti2, 17e6, 17e6, 0, "option 2 balances");
        assertAssetBalance(
            LUSDLIKE, writer, lusdBalance - (1750e18 * 17), "after write 2"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write 2");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        oti3 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti3), expected, "option 3 stored");

        // check balances
        assertTotalSupplies(clarity, oti3, 1e6, 1e6, 0, "total supplies 3");
        assertOptionBalances(clarity, writer, oti3, 1e6, 1e6, 0, "option 3 balances");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance - 1700e18, "after write 3");
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write 3");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        oti4 = clarity.writeNewPut({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 20_000e18,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 20_000e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti4), expected, "option 4 stored");

        // check balances
        assertTotalSupplies(clarity, oti4, 10e6, 10e6, 0, "total supplies 4");
        assertOptionBalances(clarity, writer, oti4, 10e6, 10e6, 0, "option 4 balances");
        assertAssetBalance(
            LUSDLIKE, writer, lusdBalance - (20_000e18 * 10), "after write 4"
        );
        assertAssetBalance(WBTCLIKE, writer, wbtcBalance, "after write 4");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        oti5 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1800e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // check option exists
        expected = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1800e6,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        assertEq(clarity.option(oti5), expected, "option 5 stored");

        // check balances
        assertTotalSupplies(clarity, oti5, 1e6, 1e6, 0, "total supplies 5");
        assertOptionBalances(clarity, writer, oti5, 1e6, 1e6, 0, "option 5 balances");
        assertAssetBalance(USDCLIKE, writer, usdcBalance - 1800e6, "after write 5");
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write 5");

        // check previous option balances did not change
        assertOptionBalances(
            clarity, writer, oti1, 0.0275e6, 0.0275e6, 0, "option 1 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti2, 17e6, 17e6, 0, "option 2 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti3, 1e6, 1e6, 0, "option 3 final balances"
        );
        assertOptionBalances(
            clarity, writer, oti4, 10e6, 10e6, 0, "option 4 final balances"
        );
    }

    function test_writeNewPut_whenFarInFutureButValidExpiry() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        // no revert
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: uint32(clarity.MAXIMUM_EXPIRY() - 1),
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function test_writeNewPut_whenLargeButValidStrikePrice() public {
        // need moar LUSD to write put with massive strike
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 1_000_000_000));

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1_000_000_000));
        // no revert
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: (2 ** 64 - 1) * 1e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function test_writeNewPut_whenAmountAtLimitOfMaximumWritable() public {
        // need moar LUSD to write massive amount of puts
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 2e18));
        // no revert
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e18,
            allowEarlyExercise: true,
            optionAmount: maximumAmount
        });
        vm.stopPrank();
    }

    // Events

    function testEvent_writeNewPut_OptionCreated() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionCreated(
            expectedOptionTokenId,
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1700e18,
            IOption.OptionType.PUT,
            IOption.ExerciseStyle.AMERICAN
        );

        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    function testEvent_writeNewPut_OptionsWritten() public {
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.005e6
        });
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writeNewPut_whenAssetsIdentical() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.AssetsIdentical.selector,
                address(WETHLIKE),
                address(WETHLIKE)
            )
        );

        vm.prank(writer);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(WETHLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenBaseAssetDecimalsTooSmall() public {
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
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenQuoteAssetDecimalsTooSmall() public {
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
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenBaseAssetDecimalsTooLarge() public {
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
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenQuoteAssetDecimalsTooLarge() public {
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
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_givenOptionAlreadyExists() public {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "before second write");

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionAlreadyExists.selector, optionTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0.8e6
        });
    }

    function testRevert_writeNewPut_whenExpiryPast() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.ExpiryPast.selector, DAWN - 1 days)
        );

        vm.prank(writer);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: DAWN - 1 days,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenStrikeTooSmall() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikeTooSmall.selector, 1e6 - 1)
        );

        vm.prank(writer);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e6 - 1,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_whenStrikeTooLarge() public {
        uint256 tooLarge = ((2 ** 64 - 1) * 1e6) + 1;

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.StrikeTooLarge.selector, tooLarge)
        );

        vm.prank(writer);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: tooLarge,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_givenInsufficientAssetBalance() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        vm.prank(brokeWriter);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
    }

    function testRevert_writeNewPut_givenInsufficientAssetApproval() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);
        deal(address(LUSDLIKE), scaleUpAssetAmount(LUSDLIKE, 1700));

        vm.startPrank(brokeWriter);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1700) - 1);

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();
    }

    /////////
    // function writeExisting(uint256 optionTokenId, uint64 optionAmount) external

    function test_writeExisting_givenCall() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeExisting(optionTokenId, 1.25e6);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(clarity, optionTokenId, 1.25e6, 1.25e6, 0, "total supplies");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1.25e6, 1.25e6, 0, "option balances"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance - (1e18 * 1.25), "after write");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write");
    }

    function test_writeExisting_givenCall_whenInitialAmountAtLimitOfMaximumWritable()
        public
    {
        // need moar WETH to write massive amount of calls
        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 2e18));
        // no revert
        clarity.writeExisting(optionTokenId, maximumAmount);
        vm.stopPrank();

        assertTotalSupplies(
            clarity, optionTokenId, maximumAmount, maximumAmount, 0, "total supplies"
        );
    }

    function test_writeExisting_givenCall_whenSubsequentAmountAtLimitOfMaximumWritable()
        public
    {
        // need moar WETH to write massive amount of calls
        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 2e18));
        clarity.writeExisting(optionTokenId, 10e6);
        // no revert
        clarity.writeExisting(optionTokenId, maximumAmount - 10e6);
        vm.stopPrank();

        assertTotalSupplies(
            clarity, optionTokenId, maximumAmount, maximumAmount, 0, "total supplies"
        );
    }

    function test_writeExisting_givenPut() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.writeExisting(optionTokenId, 1.35e6);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(clarity, optionTokenId, 1.35e6, 1.35e6, 0, "total supplies");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1.35e6, 1.35e6, 0, "option balances"
        );
        assertAssetBalance(
            LUSDLIKE, writer, lusdBalance - (1700e18 * 1.35), "after write"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance, "after write");
    }

    function test_writeExisting_givenPut_whenInitialAmountAtLimitOfMaximumWritable()
        public
    {
        // need moar LUSD to write massive amount of puts
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 2e18));
        // no revert
        clarity.writeExisting(optionTokenId, maximumAmount);
        vm.stopPrank();

        assertTotalSupplies(
            clarity, optionTokenId, maximumAmount, maximumAmount, 0, "total supplies"
        );
    }

    function test_writeExisting_givenPut_whenSubsequentAmountAtLimitOfMaximumWritable()
        public
    {
        // need moar LUSD to write massive amount of puts
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 2e18));

        uint64 maximumAmount = clarity.MAXIMUM_WRITABLE();

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 2e18));
        clarity.writeExisting(optionTokenId, 10e6);
        // no revert
        clarity.writeExisting(optionTokenId, maximumAmount - 10e6);
        vm.stopPrank();

        assertTotalSupplies(
            clarity, optionTokenId, maximumAmount, maximumAmount, 0, "total supplies"
        );
    }

    // Events

    function testEvent_writeExisting_givenCall_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.005e6);

        clarity.writeExisting(optionTokenId, 0.005e6);
        vm.stopPrank();
    }

    function testEvent_writeExisting_givenPut_OptionsWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 expectedOptionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsWritten(writer, expectedOptionTokenId, 0.006e6);

        clarity.writeExisting(optionTokenId, 0.006e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_writeExisting_givenCall_whenWriteAmountZero() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        vm.expectRevert(IOptionErrors.WriteAmountZero.selector);

        clarity.writeExisting(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenCall_whenSubsequentAmountGreaterThanMaximumWritable(
    ) public {
        // need moar WETH to write massive amount of calls
        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 2e18));

        uint64 halfTooMuch = clarity.MAXIMUM_WRITABLE() / 2;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 2e18));
        clarity.writeExisting(optionTokenId, halfTooMuch);
        clarity.writeExisting(optionTokenId, halfTooMuch);

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, 2)
        );

        clarity.writeExisting(optionTokenId, 2); // two too many
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenCall_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 optionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        vm.prank(writer);
        clarity.writeExisting(optionTokenId, 1e6);
    }

    function testRevert_writeExisting_givenCall_whenOptionExpired() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector, optionTokenId, FRI1
            )
        );

        vm.warp(FRI1 + 1 seconds);

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenCall_andInsufficientAssetBalance() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);

        vm.startPrank(brokeWriter);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenCall_andInsufficientAssetApproval() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);
        deal(address(WETHLIKE), scaleUpAssetAmount(WETHLIKE, 1));

        vm.startPrank(brokeWriter);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 1) - 1);

        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenPut_whenWriteAmountZero() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        vm.expectRevert(IOptionErrors.WriteAmountZero.selector);

        clarity.writeExisting(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenPut_whenSubsequentAmountGreaterThanMaximumWritable(
    ) public {
        // need moar LUSD to write massive amount of puts
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 2e18));

        uint64 halfTooMuch = clarity.MAXIMUM_WRITABLE() / 2;

        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 2e18));
        clarity.writeExisting(optionTokenId, halfTooMuch);
        clarity.writeExisting(optionTokenId, halfTooMuch);

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.WriteAmountTooLarge.selector, 2)
        );

        clarity.writeExisting(optionTokenId, 2); // two too many
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenPut_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });
        uint256 optionTokenId = LibPosition.hashToId(instrumentHash);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        vm.prank(writer);
        clarity.writeExisting(optionTokenId, 1e6);
    }

    function testRevert_writeExisting_givenPut_whenOptionExpired() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector, optionTokenId, FRI1
            )
        );

        vm.warp(FRI1 + 1 seconds);

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenPut_andInsufficientAssetBalance() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);

        vm.startPrank(brokeWriter);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_writeExisting_givenPut_andInsufficientAssetApproval() public {
        address brokeWriter = address(0xB0B0);
        vm.deal(brokeWriter, 10 ether);
        deal(address(LUSDLIKE), scaleUpAssetAmount(LUSDLIKE, 1700));

        vm.startPrank(brokeWriter);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1700) - 1);

        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // solmate ERC20 revert
        vm.expectRevert("TRANSFER_FROM_FAILED");

        clarity.writeExisting(optionTokenId, 1e6);
        vm.stopPrank();
    }

    /////////
    // function batchWriteExisting(uint256[] calldata optionTokenIds, uint64[] calldata
    // optionAmounts) external

    function test_batchWriteExisting() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 1.25e6;

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));

        clarity.batchWriteExisting(optionTokenIds, optionAmounts);
        vm.stopPrank();

        // check balances
        assertTotalSupplies(
            clarity, optionTokenIds[0], 1.25e6, 1.25e6, 0, "total supplies"
        );
        assertOptionBalances(
            clarity, writer, optionTokenIds[0], 1.25e6, 1.25e6, 0, "option balances"
        );
        assertAssetBalance(WETHLIKE, writer, wethBalance - (1e18 * 1.25), "after write");
        assertAssetBalance(LUSDLIKE, writer, lusdBalance, "after write");
    }

    function test_batchWriteExisting_many() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 wbtcBalance = WBTCLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 usdcBalance = USDCLIKE.balanceOf(writer);

        vm.startPrank(writer);
        uint256[] memory optionTokenIds = new uint256[](8);
        optionTokenIds[0] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[1] = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[2] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1725e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[3] = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1725e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[4] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI4,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[5] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1675e6,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[6] = clarity.writeNewCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 21_001e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[7] = clarity.writeNewPut({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI2,
            strike: 21_001e6,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        uint64[] memory optionAmounts = new uint64[](8);
        optionAmounts[0] = 1.25e6;
        optionAmounts[1] = 0.000001e6;
        optionAmounts[2] = 1.35e6;
        optionAmounts[3] = 0.5e6;
        optionAmounts[4] = 1e6;
        optionAmounts[5] = 1000e6;
        optionAmounts[6] = 1.222222e6;
        optionAmounts[7] = 0.999999e6;

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));

        clarity.batchWriteExisting(optionTokenIds, optionAmounts);
        vm.stopPrank();

        // check Clarity balances
        assertTotalSupplies(
            clarity,
            optionTokenIds[0],
            optionAmounts[0],
            optionAmounts[0],
            0,
            "option 1 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[0],
            optionAmounts[0],
            optionAmounts[0],
            0,
            "option 1 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[1],
            optionAmounts[1],
            optionAmounts[1],
            0,
            "option 2 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[1],
            optionAmounts[1],
            optionAmounts[1],
            0,
            "option 2 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[2],
            optionAmounts[2],
            optionAmounts[2],
            0,
            "option 3 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[2],
            optionAmounts[2],
            optionAmounts[2],
            0,
            "option 3 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[3],
            optionAmounts[3],
            optionAmounts[3],
            0,
            "option 4 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[3],
            optionAmounts[3],
            optionAmounts[3],
            0,
            "option 4 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[4],
            optionAmounts[4],
            optionAmounts[4],
            0,
            "option 5 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[4],
            optionAmounts[4],
            optionAmounts[4],
            0,
            "option 5 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[5],
            optionAmounts[5],
            optionAmounts[5],
            0,
            "option 6 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[5],
            optionAmounts[5],
            optionAmounts[5],
            0,
            "option 6 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[6],
            optionAmounts[6],
            optionAmounts[6],
            0,
            "option 7 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[6],
            optionAmounts[6],
            optionAmounts[6],
            0,
            "option 7 balances"
        );
        assertTotalSupplies(
            clarity,
            optionTokenIds[7],
            optionAmounts[7],
            optionAmounts[7],
            0,
            "option 8 total supplies"
        );
        assertOptionBalances(
            clarity,
            writer,
            optionTokenIds[7],
            optionAmounts[7],
            optionAmounts[7],
            0,
            "option 8 balances"
        );

        // check ERC20 balances
        uint256 expectedWethBalance = wethBalance
            - (uint256(scaleDownOptionAmount(1e18)) * optionAmounts[0])
            - (uint256(scaleDownOptionAmount(1e18)) * optionAmounts[2])
            - (uint256(scaleDownOptionAmount(1e18)) * optionAmounts[4])
            - (uint256(scaleDownOptionAmount(1e18)) * optionAmounts[5]);
        uint256 expectedWbtcBalance =
            wbtcBalance - (scaleDownOptionAmount(1e8) * optionAmounts[6]);
        uint256 expectedLusdBalance = lusdBalance
            - (uint256(scaleDownOptionAmount(1700e18)) * optionAmounts[1])
            - (uint256(scaleDownOptionAmount(1725e18)) * optionAmounts[3]);
        uint256 expectedUsdcBalance =
            usdcBalance - (scaleDownOptionAmount(21_001e6) * optionAmounts[7]);
        assertAssetBalance(WETHLIKE, writer, expectedWethBalance, "after write");
        assertAssetBalance(WBTCLIKE, writer, expectedWbtcBalance, "after write");
        assertAssetBalance(LUSDLIKE, writer, expectedLusdBalance, "after write");
        assertAssetBalance(USDCLIKE, writer, expectedUsdcBalance, "after write");
    }

    // Events

    function testEvent_batchWriteExisting_OptionsWritten() public {
        vm.startPrank(writer);
        uint256[] memory optionTokenIds = new uint256[](8);
        optionTokenIds[0] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[1] = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[2] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1725e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[3] = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1725e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[4] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI4,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[5] = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1675e6,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[6] = clarity.writeNewCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI2,
            strike: 21_001e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        optionTokenIds[7] = clarity.writeNewPut({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI2,
            strike: 21_001e6,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        uint64[] memory optionAmounts = new uint64[](8);
        optionAmounts[0] = 1.25e6;
        optionAmounts[1] = 0.000001e6;
        optionAmounts[2] = 1.35e6;
        optionAmounts[3] = 0.5e6;
        optionAmounts[4] = 1e6;
        optionAmounts[5] = 1000e6;
        optionAmounts[6] = 1.222222e6;
        optionAmounts[7] = 0.999999e6;

        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));

        for (uint256 i = 0; i < optionTokenIds.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit IOptionEvents.OptionsWritten(writer, optionTokenIds[i], optionAmounts[i]);
        }

        clarity.batchWriteExisting(optionTokenIds, optionAmounts);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_batchWriteExisting_whenArrayLengthZero() public {
        vm.expectRevert(IOptionErrors.BatchWriteArrayLengthZero.selector);

        uint256[] memory optionTokenIds = new uint256[](0);
        uint64[] memory optionAmounts = new uint64[](1);
        optionAmounts[0] = 123e6;

        vm.prank(writer);
        clarity.batchWriteExisting(optionTokenIds, optionAmounts);
    }

    function testRevert_batchWriteExisting_whenArrayLengthMismatch() public {
        vm.expectRevert(IOptionErrors.BatchWriteArrayLengthMismatch.selector);

        uint256[] memory optionTokenIds = new uint256[](1);
        optionTokenIds[0] = 213;
        uint64[] memory optionAmounts = new uint64[](2);
        optionAmounts[0] = 456e6;
        optionAmounts[1] = 789e6;

        vm.prank(writer);
        clarity.batchWriteExisting(optionTokenIds, optionAmounts);
    }

    // TODO add more tests for option expired, write amount zero, etc
}
