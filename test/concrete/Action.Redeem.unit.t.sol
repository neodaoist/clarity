// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

contract RedeemTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;
    using LibPosition for uint248;

    /////////
    // function redeem(uint256 optionTokenId)
    //     external
    //     returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed);

    // Core scenarios, where caller holds at least 1 short token:
    // - Given unassigned, When redeem short call before or on expiry (reverts)
    // - Given unassigned, When redeem short call after expiry (only write asset)
    // - Given partially assigned, When redeem short call before or on expiry (reverts)
    // - Given partially assigned, When redeem short call after expiry (both write and ex
    // asset)
    // - Given fully assigned, When redeem short call before or on expiry (only ex asset)
    // - Given fully assigned, When redeem short call after expiry (only ex asset)
    // (ditto for short put)

    // Calls

    function testRevert_redeem_shortCall_beforeOrOnExpiry_givenUnassigned() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeem(optionTokenId.longToShort());
    }

    function test_redeem_shortCall_afterExpiry_givenUnassigned() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 2.25e6, 2.25e6, 0, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 2.25e6, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1e18 * 2.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 0, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
    }

    function testRevert_redeem_shortCall_beforeOrOnExpiry_givenPartiallyAssigned()
        public
    {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 1.05e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeem(optionTokenId.longToShort());
    }

    function test_redeem_shortCall_afterExpiry_givenPartiallyAssigned() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 1.05e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.2e6, 1.05e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1e18 * 1.2, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 1.05, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeem_shortCall_beforeOrOnExpiry_givenFullyAssigned() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeem_shortCall_afterExpiry_givenFullyAssigned() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    // Puts

    function testRevert_redeem_shortPut_beforeOrOnExpiry_givenUnassigned() public {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeem(optionTokenId.longToShort());
    }

    function test_redeem_shortPut_afterExpiry_givenUnassigned() public {
        // Given
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 2.25e6, 2.25e6, 0, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 2.25e6, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1700e18 * 2.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 0, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
    }

    function testRevert_redeem_shortPut_beforeOrOnExpiry_givenPartiallyAssigned()
        public
    {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 1.05e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeem(optionTokenId.longToShort());
    }

    function test_redeem_shortPut_afterExpiry_givenPartiallyAssigned() public {
        // Given
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 1.05e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.2e6, 1.05e6, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1700e18 * 1.2, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1e18 * 1.05, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeem_shortPut_beforeOrOnExpiry_givenFullyAssigned() public {
        // Given
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeem_shortPut_afterExpiry_givenFullyAssigned() public {
        // Given
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 wethBalance = WETHLIKE.balanceOf(writer);

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    // TODO test many

    // Events

    function testEvent_redeem_call() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        }).longToShort();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.ShortsRedeemed(writer, shortTokenId);

        // When
        clarity.redeem(shortTokenId);
        vm.stopPrank();
    }

    function testEvent_redeem_put() public {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        }).longToShort();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.ShortsRedeemed(writer, shortTokenId);

        // When
        clarity.redeem(shortTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_redeem_whenLongToken() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 longTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.CanOnlyRedeemShort.selector, longTokenId)
        );

        // When
        vm.prank(writer);
        clarity.redeem(longTokenId);
    }

    function testRevert_redeem_whenAssignedShortToken() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 longTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        uint256 assignedShortTokenId = longTokenId.longToAssignedShort();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyRedeemShort.selector, assignedShortTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.redeem(assignedShortTokenId);
    }

    function testRevert_redeem_whenOptionDoesNotExist() public {
        uint256 nonexistentOptionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionType: IOption.OptionType.CALL
        }).hashToId().longToShort();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, nonexistentOptionTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.redeem(nonexistentOptionTokenId);
    }

    function testRevert_redeem_whenShortBalanceZero() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        }).longToShort();
        clarity.transfer(holder, shortTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.ShortBalanceZero.selector, shortTokenId)
        );

        // When
        vm.prank(writer);
        clarity.redeem(shortTokenId);
    }
}
