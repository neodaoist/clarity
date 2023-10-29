// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract ExerciseSimpleBackgroundPath4Test is BaseClarityMarketsTest {
    /////////

    // Happy path, Simple background, Scenarios A-F, path 4 (assignment path 1, 2, 0)

    function test_exercise_whenSimpleA_andOneHolderExercisesLessThanTicket1_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 0.1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.1e6);
        clarity.exercise(oti1, 0.1e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 2.15e6, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0.25e6, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.1e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2.4e6, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 0.1),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 0.1),
            "holder1 LUSD balance after exercise"
        );
    }

    function test_exercise_whenSimpleB_andOneHolderExercisesEqualToTicket1_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 0.15 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.15e6);
        clarity.exercise(oti1, 0.15e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 2.15e6, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0.2e6, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.15e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2.35e6, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 0.15),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 0.15),
            "holder1 LUSD balance after exercise"
        );
    }

    function test_exercise_whenSimpleC_andOneHolderExercisesLessThanTicket2_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 0.2 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.2e6);
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 2.15e6, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0.15e6, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.2e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2.3e6, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 0.2),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 0.2),
            "holder1 LUSD balance after exercise"
        );
    }

    function test_exercise_whenSimpleD_andOneHolderExercisesEqualToTicket2_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 0.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.35e6);
        checkEvent_exercise_ShortsAssigned(writer1, oti1, 0.15e6);
        clarity.exercise(oti1, 0.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 2e6, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0.15e6, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.35e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2e6, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 0.5),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 0.5),
            "holder1 LUSD balance after exercise"
        );
    }

    function test_exercise_whenSimpleE_andOneHolderExercisesLessThanTicket3_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.35e6);
        checkEvent_exercise_ShortsAssigned(writer1, oti1, 0.65e6);
        clarity.exercise(oti1, 1e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 1.5e6, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0.65e6, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.35e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 1.5e6, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 1),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 1),
            "holder1 LUSD balance after exercise"
        );
    }

    function test_exercise_whenSimpleF_andOneHolderExercisesEqualToTicket3_path4()
        public
        withSimpleBackground(exSimplePath4)
    {
        // When holder1 exercises 2.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        checkEvent_exercise_ShortsAssigned(writer2, oti1, 0.35e6);
        checkEvent_exercise_ShortsAssigned(writer1, oti1, 2e6);
        checkEvent_exercise_ShortsAssigned(writer1, oti1, 0.15e6);
        clarity.exercise(oti1, 2.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 0, "oti1 writer1 short balance after exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 2.15e6, "oti1 writer1 assigned balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0, "oti1 writer2 short balance after exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0.35e6, "oti1 writer2 assigned balance after exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 0, "oti1 holder1 long balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance after exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance after exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance + (1e18 * 2.5),
            "holder1 WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance - (1750e18 * 2.5),
            "holder1 LUSD balance after exercise"
        );
    }
}
