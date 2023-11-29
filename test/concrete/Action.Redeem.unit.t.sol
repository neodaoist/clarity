// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

contract RedeemTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;
    using LibPosition for uint248;

    /////////
    // function redeemCollateral(uint256 optionTokenId)
    //     external
    //     returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed);

    function testE2E_redeemCollateral() public {
        // Given Writer1 writes 5 options
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 5e6
        });
        vm.stopPrank();

        // And Writer2 writes 5 options
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeExisting(optionTokenId, 5e6);
        vm.stopPrank();

        // And Writer1 transfers 5 options to Holder1
        vm.prank(writer1);
        clarity.transfer(holder1, optionTokenId, 5e6);

        // And Writer2 transfers 3 options to Holder1
        vm.prank(writer2);
        clarity.transfer(holder1, optionTokenId, 3e6);

        // And Writer2 transfers 2 options to Holder2
        vm.prank(writer2);
        clarity.transfer(holder2, optionTokenId, 2e6);

        // pre checks (before exercise)
        assertTotalSupplies(optionTokenId, 10e6, 10e6, 0, "before exercise");
        assertOptionBalances(writer1, optionTokenId, 0, 5e6, 0, "writer1 before exercise");
        assertOptionBalances(writer2, optionTokenId, 0, 5e6, 0, "writer2 before exercise");
        assertOptionBalances(holder1, optionTokenId, 8e6, 0, 0, "holder1 before exercise");
        assertOptionBalances(holder2, optionTokenId, 2e6, 0, 0, "holder2 before exercise");

        // And time warps to at expiry
        vm.warp(FRI1);

        // And Holder2 exercises 2 options
        vm.startPrank(holder2);
        FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 2e6);
        vm.stopPrank();

        // pre checks (before expiry)
        assertTotalSupplies(optionTokenId, 8e6, 8e6, 2e6, "before expiry");
        assertOptionBalances(writer1, optionTokenId, 0, 4e6, 1e6, "writer1 before expiry");
        assertOptionBalances(writer2, optionTokenId, 0, 4e6, 1e6, "writer2 before expiry");
        assertOptionBalances(holder1, optionTokenId, 8e6, 0, 0, "holder1 before expiry");
        assertOptionBalances(holder2, optionTokenId, 0, 0, 0, "holder2 before expiry");

        // And time warps to after expiry
        vm.warp(FRI1 + 1 seconds);

        // pre checks (after expiry)
        assertTotalSupplies(optionTokenId, 0, 8e6, 2e6, "after expiry");
        assertOptionBalances(writer1, optionTokenId, 0, 4e6, 1e6, "writer1 after expiry");
        assertOptionBalances(writer2, optionTokenId, 0, 4e6, 1e6, "writer2 after expiry");
        assertOptionBalances(holder1, optionTokenId, 0, 0, 0, "holder1 after expiry");
        assertOptionBalances(holder2, optionTokenId, 0, 0, 0, "holder2 after expiry");

        uint256 wethBalance1 = WETHLIKE.balanceOf(writer1);
        uint256 fraxBalance1 = FRAXLIKE.balanceOf(writer1);
        uint256 wethBalance2 = WETHLIKE.balanceOf(writer2);
        uint256 fraxBalance2 = FRAXLIKE.balanceOf(writer2);

        // When Writer1 redeems collateral
        vm.prank(writer1);
        (uint128 writeAssetRedeemed1, uint128 exerciseAssetRedeemed1) =
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertTotalSupplies(optionTokenId, 0, 4e6, 1e6, "after redeem1");
        assertOptionBalances(writer1, optionTokenId, 0, 0, 0, "writer1 after redeem1");
        assertOptionBalances(writer2, optionTokenId, 0, 4e6, 1e6, "writer2 after redeem1");
        assertOptionBalances(holder1, optionTokenId, 0, 0, 0, "holder1 after redeem1");
        assertOptionBalances(holder2, optionTokenId, 0, 0, 0, "holder2 after redeem1");
        assertEq(writeAssetRedeemed1, 1e18 * 4, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed1, 2050e18, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer1, WETHLIKE, wethBalance1 + writeAssetRedeemed1, "after redeem"
        );
        assertAssetBalance(
            writer, FRAXLIKE, fraxBalance1 + exerciseAssetRedeemed1, "after redeem"
        );

        // When Writer2 redeems collateral
        vm.prank(writer2);
        (uint128 writeAssetRedeemed2, uint128 exerciseAssetRedeemed2) =
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertTotalSupplies(optionTokenId, 0, 0, 0, "after redeem2");
        assertOptionBalances(writer1, optionTokenId, 0, 0, 0, "writer1 after redeem2");
        assertOptionBalances(writer2, optionTokenId, 0, 0, 0, "writer2 after redeem2");
        assertOptionBalances(holder1, optionTokenId, 0, 0, 0, "holder1 after redeem2");
        assertOptionBalances(holder2, optionTokenId, 0, 0, 0, "holder2 after redeem2");
        assertEq(writeAssetRedeemed2, 1e18 * 4, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed2, 2050e18, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer1, WETHLIKE, wethBalance2 + writeAssetRedeemed2, "after redeem"
        );
        assertAssetBalance(
            writer, FRAXLIKE, fraxBalance2 + exerciseAssetRedeemed2, "after redeem"
        );
    }

    // Core scenarios, where caller holds at least 1 short token:
    // - Given unassigned, When redeem short call before or on expiry (reverts)
    // - Given unassigned, When redeem short call after expiry (only write asset)
    // - Given partially assigned, When redeem short call before or on expiry (reverts)
    // - Given partially assigned, When redeem short call after expiry (write & ex asset)
    // - Given fully assigned, When redeem short call before or on expiry (only ex asset)
    // - Given fully assigned, When redeem short call after expiry (only ex asset)
    // (ditto for short put)

    // Calls

    function testRevert_redeemCollateral_A_shortCall_beforeOrOnExpiry_givenUnassigned()
        public
    {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        vm.warp(FRI1);

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeemCollateral(optionTokenId.longToShort());
    }

    function test_redeemCollateral_B_shortCall_afterExpiry_givenUnassigned() public {
        // Given
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
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        // pre checks, before expiry
        assertTotalSupplies(optionTokenId, 2.25e6, 2.25e6, 0, "before expiry");
        assertOptionBalances(writer, optionTokenId, 2.25e6, 2.25e6, 0, "before expiry");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before expiry");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before expiry");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(FRI1 + 1 seconds);

        // pre checks, after expiry (longs go to 0, bc open interest is all expired)
        assertTotalSupplies(optionTokenId, 0, 2.25e6, 0, "after expiry");
        assertOptionBalances(writer, optionTokenId, 0, 2.25e6, 0, "after expiry");

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertTotalSupplies(optionTokenId, 0, 0, 0, "after redeem");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1e18 * 2.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 0, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
    }

    function testRevert_redeemCollateral_C_shortCall_beforeOrOnExpiry_givenPartiallyAssigned(
    ) public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 1.05e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeemCollateral(optionTokenId.longToShort());
    }

    function test_redeemCollateral_D_shortCall_afterExpiry_givenPartiallyAssigned()
        public
    {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 1.05e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.2e6, 1.05e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(FRI1 + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

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

    function test_redeemCollateral_E_shortCall_beforeOrOnExpiry_givenFullyAssigned()
        public
    {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 2.25e6);
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
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeemCollateral_F_shortCall_afterExpiry_givenFullyAssigned() public {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(FRI1 + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

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

    function testRevert_redeemCollateral_A_shortPut_beforeOrOnExpiry_givenUnassigned()
        public
    {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        vm.warp(FRI1);

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeemCollateral(optionTokenId.longToShort());
    }

    function test_redeemCollateral_B_shortPut_afterExpiry_givenUnassigned() public {
        // Given
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

        vm.warp(FRI1 + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 1700e18 * 2.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 0, "exerciseAssetRedeemed");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
    }

    function testRevert_redeemCollateral_C_shortPut_beforeOrOnExpiry_givenPartiallyAssigned(
    ) public {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 1.05e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.EarlyRedemptionOnlyIfFullyAssigned.selector);

        // When
        vm.prank(writer);
        clarity.redeemCollateral(optionTokenId.longToShort());
    }

    function test_redeemCollateral_shortPut_D_afterExpiry_givenPartiallyAssigned()
        public
    {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 1.05e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.2e6, 1.05e6, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.warp(FRI1 + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

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

    function test_redeemCollateral_shortPut_E_beforeOrOnExpiry_givenFullyAssigned()
        public
    {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 2.25e6);
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
            clarity.redeemCollateral(optionTokenId.longToShort());

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1e18 * 2.25, "exerciseAssetRedeemed");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function test_redeemCollateral_shortPut_F_afterExpiry_givenFullyAssigned() public {
        // Given
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
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1);

        vm.startPrank(holder);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.exerciseOption(optionTokenId, 2.25e6);
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance - (1700e18 * 2.25), "before redeem"
        );
        assertAssetBalance(writer, WETHLIKE, wethBalance, "before redeem");

        lusdBalance = LUSDLIKE.balanceOf(writer);
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.warp(FRI1 + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(optionTokenId.longToShort());

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

    function testEvent_redeemCollateral_call_CollateralRedeemed() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        }).longToShort();

        vm.warp(FRI1 + 1 seconds);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.CollateralRedeemed(writer, shortTokenId);

        // When
        clarity.redeemCollateral(shortTokenId);
        vm.stopPrank();
    }

    function testEvent_redeemCollateral_put_CollateralRedeemed() public {
        // Given
        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        }).longToShort();

        vm.warp(FRI1 + 1 seconds);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.CollateralRedeemed(writer, shortTokenId);

        // When
        clarity.redeemCollateral(shortTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_redeemCollateral_whenLongToken() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 longTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyRedeemCollateral.selector, longTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.redeemCollateral(longTokenId);
    }

    function testRevert_redeemCollateral_whenAssignedShortToken() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 longTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        uint256 assignedShortTokenId = longTokenId.longToAssignedShort();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyRedeemCollateral.selector, assignedShortTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.redeemCollateral(assignedShortTokenId);
    }

    function testRevert_redeemCollateral_whenOptionDoesNotExist() public {
        uint256 nonexistentOptionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        }).hashToId().longToShort();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, nonexistentOptionTokenId
            )
        );

        // When
        vm.prank(writer);
        clarity.redeemCollateral(nonexistentOptionTokenId);
    }

    function testRevert_redeemCollateral_whenShortBalanceZero() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 shortTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        }).longToShort();
        clarity.transfer(holder, shortTokenId, 2.25e6);
        vm.stopPrank();

        vm.warp(FRI1 + 1 seconds);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.ShortBalanceZero.selector, shortTokenId)
        );

        // When
        vm.prank(writer);
        clarity.redeemCollateral(shortTokenId);
    }
}
