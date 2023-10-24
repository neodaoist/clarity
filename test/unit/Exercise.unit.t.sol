// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract ExerciseTest is BaseClarityMarketsTest {
    /////////

    // function exercise(uint256 _optionTokenId, uint80 optionsAmount) external

    function test_exercise() public {
        uint256 writerWethBalance = WETHLIKE.balanceOf(writer);
        uint256 writerLusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 holderWethBalance = WETHLIKE.balanceOf(holder);
        uint256 holderLusdBalance = LUSDLIKE.balanceOf(holder);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 2.25e6);
        bool success = clarity.transfer(holder, optionTokenId, 1.15e6);
        require(success);
        vm.stopPrank();

        // pre exercise checks
        assertEq(clarity.balanceOf(writer, optionTokenId), 1.1e6, "writer long balance before exercise");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 2.25e6, "writer short balance before exercise");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "writer assigned balance before exercise");
        assertEq(clarity.balanceOf(holder, optionTokenId), 1.15e6, "holder long balance before exercise");
        assertEq(clarity.balanceOf(holder, optionTokenId + 1), 0, "holder short balance before exercise");
        assertEq(clarity.balanceOf(holder, optionTokenId + 2), 0, "holder assigned balance before exercise");
        assertEq(
            WETHLIKE.balanceOf(writer),
            writerWethBalance - (1e18 * 2.25),
            "writer WETH balance before exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer), writerLusdBalance, "writer LUSD balance before exercise");
        assertEq(WETHLIKE.balanceOf(holder), holderWethBalance, "holder WETH balance before exercise");
        assertEq(LUSDLIKE.balanceOf(holder), holderLusdBalance, "holder LUSD balance before exercise");

        // exercise
        vm.warp(americanExWeeklies[0][1]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 0.8e6);
        vm.stopPrank();

        // post exercise checks
        assertEq(clarity.balanceOf(writer, optionTokenId), 1.1e6, "writer long balance after exercise");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1.45e6, "writer short balance after exercise");
        assertEq(
            clarity.balanceOf(writer, optionTokenId + 2), 0.8e6, "writer assigned balance after exercise"
        );
        assertEq(clarity.balanceOf(holder, optionTokenId), 0.35e6, "holder long balance after exercise");
        assertEq(clarity.balanceOf(holder, optionTokenId + 1), 0, "holder short balance after exercise");
        assertEq(clarity.balanceOf(holder, optionTokenId + 2), 0, "holder assigned balance after exercise");
        assertEq(
            WETHLIKE.balanceOf(writer),
            writerWethBalance - (1e18 * 2.25),
            "writer WETH balance after exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer), writerLusdBalance, "writer LUSD balance after exercise");
        assertEq(
            WETHLIKE.balanceOf(holder), writerWethBalance + (1e18 * 0.8), "holder WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder),
            writerLusdBalance - (1700e18 * 0.8),
            "holder LUSD balance after exercise"
        );
    }

    // TODO

    function testRevert_exercise_whenExerciseAmountZero() public {
        vm.expectRevert(OptionErrors.ExerciseAmountZero.selector);

        vm.prank(holder);
        clarity.exercise(123, 0);
    }

    function testRevert_exercise_whenOptionDoesNotExist() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, 123));

        vm.prank(holder);
        clarity.exercise(123, 1e6);
    }

    function testRevert_exercise_whenOptionTokenIdNotLong() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, optionTokenId + 1));

        vm.prank(holder);
        clarity.exercise(optionTokenId + 1, 1e6);

        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, optionTokenId + 2));

        vm.prank(holder);
        clarity.exercise(optionTokenId + 2, 1e6);
    }

    function testRevert_exercise_whenOptionNotWithinExerciseWindow() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();

        // before exerciseTimestamp
        vm.warp(americanExWeeklies[0][0] - 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionNotWithinExerciseWindow.selector,
                americanExWeeklies[0][0],
                americanExWeeklies[0][1]
            )
        );

        vm.prank(writer);
        clarity.exercise(optionTokenId, 1e6);

        // after expityTimestamp
        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionNotWithinExerciseWindow.selector,
                americanExWeeklies[0][0],
                americanExWeeklies[0][1]
            )
        );

        vm.prank(writer);
        clarity.exercise(optionTokenId, 1e6);
    }

    function testRevert_exercise_whenExerciseAmountExceedsLongBalance() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][0]);

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.ExerciseAmountExceedsLongBalance.selector, 1.000001e6, 1e6)
        );

        vm.prank(writer);
        clarity.exercise(optionTokenId, 1.000001e6);
    }

    // TODO revert on too much decimal precision
}
