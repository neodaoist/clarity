// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract RedeemTest is BaseClarityMarketsTest {
    /////////

    using LibToken for uint256;

    /////////
    // function redeem(uint256 optionTokenId)
    //     external
    //     returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed);

    // Core scenarios:
    // - redeem short call, when unassigned, and on or before expiry (reverts, nothing to redeem)
    // - redeem short call, when unassigned, and after expiry (only write asset redeemed)
    // - redeem short call, when partially assigned, and on or before expiry (only exercise asset)
    // - redeem short call, when partially assigned, and after expiry (both write and ex asset)
    // - redeem short call, when fully assigned, and on or before expiry (only exercise asset)
    // - redeem short call, when fully assigned, and after expiry (same as previous scenario)
    // (ditto for short put)

    function txestRevert_redeem_shortCall_whenUnassigned_AndOnOrBeforeExpiry() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1]);

        // Then
        vm.expectRevert(OptionErrors.NoAssetsToRedeem.selector);

        // When
        vm.prank(writer);
        clarity.redeem(optionTokenId);
    }

    function txest_redeem_shortCall_whenUnassigned_AndAfterExpiry() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
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
            clarity.redeem(optionTokenId);

        // Then
        assertEq(writeAssetRedeemed, 1e18 * 2.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 0, "exerciseAssetRedeemed");
        assertOptionBalances(writer, optionTokenId, 2.25e6, 0, 0, "after redeem");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "after redeem");
    }

    function txest_redeem_shortCall_whenPartiallyAssigned_AndOnOrBeforeExpiry() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.prank(holder);
        clarity.exercise(optionTokenId, 1.05e6);

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.25e6, 1.05e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1]);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId);

        // Then
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 1.05, "exerciseAssetRedeemed");
        assertOptionBalances(writer, optionTokenId, 0, 1.25e6, 0, "after redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function txest_redeem_shortCall_whenPartiallyAssigned_AndAfterExpiry() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.prank(holder);
        clarity.exercise(optionTokenId, 1.05e6);

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 1.25e6, 1.05e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId);

        // Then
        assertEq(writeAssetRedeemed, 1e18 * 1.25, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 1.05, "exerciseAssetRedeemed");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertAssetBalance(
            writer, WETHLIKE, wethBalance + writeAssetRedeemed, "after redeem"
        );
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function txest_redeem_shortCall_whenFullyAssigned_AndOnOrBeforeExpiry() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.prank(holder);
        clarity.exercise(optionTokenId, 2.25e6);

        // pre checks
        assertOptionBalances(writer, optionTokenId, 0, 0, 2.25e6, "before redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance - (1e18 * 2.25), "before redeem");
        assertAssetBalance(writer, LUSDLIKE, lusdBalance, "before redeem");

        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.warp(americanExWeeklies[0][1]);

        // When
        vm.prank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeem(optionTokenId);

        // Then
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 2.25e6, "exerciseAssetRedeemed");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    function txest_redeem_shortCall_whenFullyAssigned_AndAfterExpiry() public {
        // Given
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e18,
            optionAmount: 2.25e6
        });
        clarity.transfer(holder, optionTokenId, 2.25e6);
        vm.stopPrank();

        vm.prank(holder);
        clarity.exercise(optionTokenId, 2.25e6);

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
            clarity.redeem(optionTokenId);

        // Then
        assertEq(writeAssetRedeemed, 0, "writeAssetRedeemed");
        assertEq(exerciseAssetRedeemed, 1700e18 * 2.25e6, "exerciseAssetRedeemed");
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "after redeem");
        assertAssetBalance(writer, WETHLIKE, wethBalance, "after redeem");
        assertAssetBalance(
            writer, LUSDLIKE, lusdBalance + exerciseAssetRedeemed, "after redeem"
        );
    }

    // TODO test redeem short put

    // Events

    // TODO

    // Sad Paths

    // TODO
}
