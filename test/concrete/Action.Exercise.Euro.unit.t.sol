// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseExerciseUnitTestSuite.t.sol";

contract EuropeanExerciseTest is BaseExerciseUnitTestSuite {
    /////////

    /////////
    // function exerciseOption(uint256 _optionTokenId, uint64 optionsAmount) external

    function test_exerciseOption_givenEuropean() public {
        uint256 startingBalanceD18 = scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE);

        // Given Writer writes 1 European call option
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), startingBalanceD18);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2000e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });

        // And transfer 0.6 options to Holder
        clarity.transfer(holder, optionTokenId, 0.6e6);
        vm.stopPrank();

        // pre checks
        // option balances
        assertTotalSupplies(optionTokenId, 1e6, 1e6, 0, "total supplies before exercise");
        assertOptionBalances(
            writer, optionTokenId, 0.4e6, 1e6, 0, "writer option balances before exercise"
        );
        assertOptionBalances(
            holder, optionTokenId, 0.6e6, 0, 0, "holder option balances before exercise"
        );

        // asset balances
        assertEq(
            WETHLIKE.balanceOf(writer),
            startingBalanceD18 - 1e18,
            "writer WETHLIKE balance before exercise"
        );
        assertEq(
            FRAXLIKE.balanceOf(writer),
            startingBalanceD18,
            "writer FRAXLIKE balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder),
            startingBalanceD18,
            "holder WETHLIKE balance before exercise"
        );
        assertEq(
            FRAXLIKE.balanceOf(holder),
            startingBalanceD18,
            "holder FRAXLIKE balance before exercise"
        );

        // And current time is within exercise window of option
        vm.warp(FRI2 - 1 days);

        // When Holder exercises 0.5 options
        vm.startPrank(holder);
        FRAXLIKE.approve(address(clarity), startingBalanceD18);
        clarity.exerciseOption(optionTokenId, 0.55e6);
        vm.stopPrank();

        // Then
        // option balances
        assertTotalSupplies(
            optionTokenId, 0.45e6, 0.45e6, 0.55e6, "total supplies after exercise"
        );
        assertOptionBalances(
            writer,
            optionTokenId,
            0.4e6,
            0.45e6,
            0.55e6,
            "writer option balances after exercise"
        );
        assertOptionBalances(
            holder, optionTokenId, 0.05e6, 0, 0, "holder option balances after exercise"
        );

        // asset balances
        assertEq(
            WETHLIKE.balanceOf(writer),
            startingBalanceD18 - 1e18,
            "writer WETHLIKE balance after exercise"
        );
        assertEq(
            FRAXLIKE.balanceOf(writer),
            startingBalanceD18,
            "writer FRAXLIKE balance after exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder),
            startingBalanceD18 + (1e18 * 0.55),
            "holder WETHLIKE balance after exercise"
        );
        assertEq(
            FRAXLIKE.balanceOf(holder),
            startingBalanceD18 - (2000e18 * 0.55),
            "holder FRAXLIKE balance after exercise"
        );
    }

    // Events (see American Exercise unit test suite)

    // Sad Paths

    function testRevert_exercise_GivenEuropean_andBeforeExerciseWindow() public {
        uint256 startingBalanceD18 = scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE);

        // Given Writer writes 1 European call option
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), startingBalanceD18);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2000e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });

        // And transfer 0.6 options to Holder
        clarity.transfer(holder, optionTokenId, 0.6e6);
        vm.stopPrank();

        // And current time is before exercise window of option
        vm.warp(FRI2 - 1 days - 1 seconds);

        // When Holder exercises 0.5 options
        vm.startPrank(holder);
        FRAXLIKE.approve(address(clarity), startingBalanceD18);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionNotWithinExerciseWindow.selector, FRI2 - 1 days, FRI2
            )
        );

        clarity.exerciseOption(optionTokenId, 0.55e6);
        vm.stopPrank();
    }

    function testRevert_exercise_GivenEuropean_andAfterExerciseWindow() public {
        uint256 startingBalanceD18 = scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE);

        // Given Writer writes 1 European call option
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), startingBalanceD18);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2000e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });

        // And transfer 0.6 options to Holder
        clarity.transfer(holder, optionTokenId, 0.6e6);
        vm.stopPrank();

        // And current time is before exercise window of option
        vm.warp(FRI2 + 1 seconds);

        // When Holder exercises 0.5 options
        vm.startPrank(holder);
        FRAXLIKE.approve(address(clarity), startingBalanceD18);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionNotWithinExerciseWindow.selector, FRI2 - 1 days, FRI2
            )
        );

        clarity.exerciseOption(optionTokenId, 0.55e6);
        vm.stopPrank();
    }
}
