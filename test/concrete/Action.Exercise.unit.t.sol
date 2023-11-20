// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

contract ExerciseTest is BaseUnitTestSuite {
    /////////

    // state variables to avoid stack too deep
    uint256 internal writer1WethBalance;
    uint256 internal writer1LusdBalance;
    uint256 internal writer2WethBalance;
    uint256 internal writer2LusdBalance;
    uint256 internal writer3WethBalance;
    uint256 internal writer3LusdBalance;
    uint256 internal holder1WethBalance;
    uint256 internal holder1LusdBalance;
    uint256 internal holder2WethBalance;
    uint256 internal holder2LusdBalance;
    uint256 internal holder3WethBalance;
    uint256 internal holder3LusdBalance;

    /////////
    // function exerciseLongs(uint256 _optionTokenId, uint64 optionsAmount) external

    function test_exerciseLongs() public {
        uint256 writerWethBalance = WETHLIKE.balanceOf(writer);
        uint256 writerLusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 holderWethBalance = WETHLIKE.balanceOf(holder);
        uint256 holderLusdBalance = LUSDLIKE.balanceOf(holder);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1700e18, true, 2.25e6
        );
        bool success = clarity.transfer(holder, optionTokenId, 1.15e6);
        require(success);
        vm.stopPrank();

        // pre exercise checks
        assertEq(
            clarity.balanceOf(writer, optionTokenId),
            1.1e6,
            "writer long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToShort(optionTokenId)),
            2.25e6,
            "writer short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "writer assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, optionTokenId),
            1.15e6,
            "holder long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToShort(optionTokenId)),
            0,
            "holder short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "holder assigned balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer),
            writerWethBalance - (1e18 * 2.25),
            "writer WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer),
            writerLusdBalance,
            "writer LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder),
            holderWethBalance,
            "holder WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder),
            holderLusdBalance,
            "holder LUSD balance before exercise"
        );

        // exercise
        vm.warp(expiryWeeklies[0]);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(optionTokenId, 0.8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, optionTokenId),
            1.1e6,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(optionTokenId)),
            (2.25e6 * (2.25e6 - 0.8e6)) / 2.25e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(optionTokenId)),
            (2.25e6 * 0.8e6) / 2.25e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, optionTokenId),
            0.35e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(optionTokenId)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer),
            writerWethBalance - (1e18 * 2.25),
            "writer WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer),
            writerLusdBalance,
            "writer LUSD balance after exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder),
            writerWethBalance + (1e18 * 0.8),
            "holder WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder),
            writerLusdBalance - (1700e18 * 0.8),
            "holder LUSD balance after exercise"
        );
    }

    // Happy path, Simple background, Scenarios A-F

    function test_exerciseLongs_whenSimpleA_andOneHolderExercisesLessThanWrite1()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 0.1e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            (2.15e6 * (2.5e6 - 0.1e6)) / 2.5e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            (2.15e6 * 0.1e6) / 2.5e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            (0.35e6 * (2.5e6 - 0.1e6)) / 2.5e6,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            (0.35e6 * 0.1e6) / 2.5e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.4e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    function test_exerciseLongs_whenSimpleB_andOneHolderExercisesEqualToWrite1()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.15 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 0.15e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            (2.15e6 * (2.5e6 - 0.15e6)) / 2.5e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            (2.15e6 * 0.15e6) / 2.5e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            (0.35e6 * (2.5e6 - 0.15e6)) / 2.5e6,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            (0.35e6 * 0.15e6) / 2.5e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.35e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    function test_exerciseLongs_whenSimpleC_andOneHolderExercisesLessThanWrite2()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.2 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 0.2e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            (2.15e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            (2.15e6 * 0.2e6) / 2.5e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            (0.35e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            (0.35e6 * 0.2e6) / 2.5e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.3e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    function test_exerciseLongs_whenSimpleD_andOneHolderExercisesEqualToWrite2()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 0.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            (2.15e6 * (2.5e6 - 0.5e6)) / 2.5e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            (2.15e6 * 0.5e6) / 2.5e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            (0.35e6 * (2.5e6 - 0.5e6)) / 2.5e6,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            (0.35e6 * 0.5e6) / 2.5e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    function test_exerciseLongs_whenSimpleE_andOneHolderExercisesLessThanWrite3()
        public
        withSimpleBackground
    {
        // When holder1 exercises 1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 1e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            (2.15e6 * (2.5e6 - 1e6)) / 2.5e6,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            (2.15e6 * 1e6) / 2.5e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            (0.35e6 * (2.5e6 - 1e6)) / 2.5e6,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            (0.35e6 * 1e6) / 2.5e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            1.5e6,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    function test_exerciseLongs_whenSimpleF_andOneHolderExercisesEqualToWrite3()
        public
        withSimpleBackground
    {
        // When holder1 exercises 2.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(oti1, 2.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToShort(oti1)),
            0,
            "oti1 writer1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)),
            2.15e6,
            "oti1 writer1 assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToShort(oti1)),
            0,
            "oti1 writer2 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)),
            0.35e6,
            "oti1 writer2 assigned balance after exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            0,
            "oti1 holder1 long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToShort(oti1)),
            0,
            "oti1 holder1 short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)),
            0,
            "oti1 holder1 assigned balance after exercise"
        );

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

    // function test_exerciseLongs_many_whenComplex_AndOneHolderExercisesAllOnce() public
    // withComplexBackground {
    //     // When holder1 exercises 2.45 options of oti1
    //     vm.startPrank(holder1);
    //     LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE,
    // STARTING_BALANCE));
    //     clarity.exerciseLongs(oti1, 2.45e6);
    //     vm.stopPrank();

    //     // Then
    //     // check option balances
    //     assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance after
    // exercise");
    //     assertEq(clarity.balanceOf(writer1, LibPosition.longToShort(oti1)), 777, "oti1
    // writer1 short balance after exercise");
    //     assertEq(clarity.balanceOf(writer1, LibPosition.longToAssignedShort(oti1)), 0,
    // "oti1 writer1 assigned balance after exercise");
    //     assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance after
    // exercise");
    //     assertEq(clarity.balanceOf(writer2, LibPosition.longToShort(oti1)), 888, "oti1
    // writer2 short balance after exercise");
    //     assertEq(clarity.balanceOf(writer2, LibPosition.longToAssignedShort(oti1)), 0,
    // "oti1 writer2 assigned balance after exercise");
    //     assertEq(clarity.balanceOf(writer3, oti1), 0, "oti1 writer3 long balance after
    // exercise");
    //     assertEq(clarity.balanceOf(writer3, LibPosition.longToShort(oti1)), 999, "oti1
    // writer3 short balance after exercise");
    //     assertEq(clarity.balanceOf(writer3, LibPosition.longToAssignedShort(oti1)), 0,
    // "oti1 writer3 assigned balance after exercise");
    //     assertEq(clarity.balanceOf(holder1, oti1), 0, "oti1 holder1 long balance after
    // exercise");
    //     assertEq(clarity.balanceOf(holder1, LibPosition.longToShort(oti1)), 0, "oti1
    // holder1 short balance after exercise");
    //     assertEq(clarity.balanceOf(holder1, LibPosition.longToAssignedShort(oti1)), 0,
    // "oti1 holder1 assigned balance after exercise");

    //     // check asset balances
    //     assertEq(WETHLIKE.balanceOf(holder1), holder1WethBalance, "holder1 WETH balance
    // after exercise");
    //     assertEq(
    //         LUSDLIKE.balanceOf(holder1),
    //         holder1LusdBalance - (1700e6 * 2.25),
    //         "holder1 LUSD balance after exercise"
    //     );
    // }

    function test_exerciseLongs_upperBounds() public {
        uint256 numWrites = 3000;
        uint256 optionAmountWritten;

        deal(address(LUSDLIKE), holder, scaleUpAssetAmount(LUSDLIKE, 1_000_000_000_000));

        uint256 holderWethBalance = WETHLIKE.balanceOf(holder);
        uint256 holderLusdBalance = LUSDLIKE.balanceOf(holder);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1700e18, true, 0
        );
        for (uint256 i = 0; i < numWrites; i++) {
            uint64 amount = uint64(
                bound(
                    uint256(keccak256(abi.encodePacked("setec astronomy", i))),
                    0,
                    type(uint24).max
                )
            );
            optionAmountWritten += amount;

            clarity.writeExisting(optionTokenId, amount);
        }
        clarity.transfer(holder, optionTokenId, optionAmountWritten);
        vm.stopPrank();

        // pre exercise checks
        assertEq(
            clarity.balanceOf(writer, optionTokenId),
            0,
            "writer long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToShort(optionTokenId)),
            optionAmountWritten,
            "writer short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "writer assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, optionTokenId),
            optionAmountWritten,
            "holder long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToShort(optionTokenId)),
            0,
            "holder short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "holder assigned balance before exercise"
        );

        vm.warp(expiryWeeklies[1] - 1 seconds);
        vm.startPrank(holder);
        LUSDLIKE.approve(
            address(clarity), scaleUpAssetAmount(LUSDLIKE, 1_000_000_000_000)
        );
        clarity.exerciseLongs(optionTokenId, uint64(optionAmountWritten));
        vm.stopPrank();

        // check option balances
        assertEq(
            clarity.balanceOf(writer, optionTokenId),
            0,
            "writer long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToShort(optionTokenId)),
            0,
            "writer short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(writer, LibPosition.longToAssignedShort(optionTokenId)),
            optionAmountWritten,
            "writer assigned balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder, optionTokenId),
            0,
            "holder long balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToShort(optionTokenId)),
            0,
            "holder short balance after exercise"
        );
        assertEq(
            clarity.balanceOf(holder, LibPosition.longToAssignedShort(optionTokenId)),
            0,
            "holder assigned balance after exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(holder),
            holderWethBalance + scaleDownOptionAmount(1e18) * optionAmountWritten,
            "holder WETH balance after exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder),
            holderLusdBalance - scaleDownOptionAmount(1700e18) * optionAmountWritten,
            "holder LUSD balance after exercise"
        );
    }

    // Events

    function testEvent_exerciseLongs_OptionsExercised() public withSimpleBackground {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsExercised(holder, oti1, 1.000005e6);

        clarity.exerciseLongs(oti1, 1.000005e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_exerciseLongs_whenExerciseAmountZero() public {
        vm.expectRevert(IOptionErrors.ExerciseAmountZero.selector);

        vm.prank(holder);
        clarity.exerciseLongs(123, 0);
    }

    function testRevert_exerciseLongs_whenOptionDoesNotExist() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, 123)
        );

        vm.prank(holder);
        clarity.exerciseLongs(123, 1e6);
    }

    // function testRevert_exerciseLongs_whenOptionTokenIdNotLong() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE,
    // STARTING_BALANCE));
    //     uint256 optionTokenId =
    //         clarity.writeNewCall(address(WETHLIKE), address(LUSDLIKE),
    // expiryWeeklies[0], 1700e18, 1e6);
    //     vm.stopPrank();

    //     uint256 short = Y;
    //     vm.expectRevert(abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector,
    // short));

    //     vm.prank(holder);
    //     clarity.exerciseLongs(short, 1e6);

    //     uint256 assignedShort = Z;
    //     vm.expectRevert(abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector,
    // assignedShort));

    //     vm.prank(holder);
    //     clarity.exerciseLongs(assignedShort, 1e6);
    // }

    function testRevert_exerciseLongs_whenOptionNotWithinExerciseWindow() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1700e18, true, 1e6
        );
        vm.stopPrank();

        // before exerciseTimestamp
        vm.warp(expiryWeeklies[0] - 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionNotWithinExerciseWindow.selector,
                1,
                expiryWeeklies[0]
            )
        );

        vm.prank(writer);
        clarity.exerciseLongs(optionTokenId, 1e6);

        // after expiryTimestamp
        vm.warp(expiryWeeklies[0] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionNotWithinExerciseWindow.selector,
                1,
                expiryWeeklies[0]
            )
        );

        vm.prank(writer);
        clarity.exerciseLongs(optionTokenId, 1e6);
    }

    function testRevert_exerciseLongs_whenExerciseAmountExceedsLongBalance() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1700e18,true, 1e6
        );
        vm.stopPrank();

        vm.warp(expiryWeeklies[1] - 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseAmountExceedsLongBalance.selector, 1.000001e6, 1e6
            )
        );

        vm.prank(writer);
        clarity.exerciseLongs(optionTokenId, 1.000001e6);
    }

    // TODO revert on too much decimal precision

    ///////// Test Backgrounds

    modifier withSimpleBackground() {
        writer1WethBalance = WETHLIKE.balanceOf(writer1);
        writer1LusdBalance = LUSDLIKE.balanceOf(writer1);
        writer2WethBalance = WETHLIKE.balanceOf(writer2);
        writer2LusdBalance = LUSDLIKE.balanceOf(writer2);
        holder1WethBalance = WETHLIKE.balanceOf(holder1);
        holder1LusdBalance = LUSDLIKE.balanceOf(holder1);

        // Given writer1 writes 0.15 options of oti1
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        oti1 = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1750e18, true, 0.15e6
        );
        vm.stopPrank();

        // And writer2 writes 0.35 options of oti1
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeExisting(oti1, 0.35e6);
        vm.stopPrank();

        // And writer1 writes 2 options of oti1
        vm.prank(writer1);
        clarity.writeExisting(oti1, 2e6);

        // And writer1 transfers 2.15 longs of oti1 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti1, 2.15e6);

        // And writer2 transfers 0.35 longs of oti1 to holder1
        vm.prank(writer2);
        clarity.transfer(holder1, oti1, 0.35e6);

        // pre exercise check option balances
        // oti1
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 1),
            2.15e6,
            "oti1 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 2),
            0,
            "oti1 writer1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 1),
            0.35e6,
            "oti1 writer2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 2),
            0,
            "oti1 writer2 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.5e6,
            "oti1 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 1),
            0,
            "oti1 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 2),
            0,
            "oti1 holder1 assigned balance before exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.15),
            "writer1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer1),
            writer1LusdBalance,
            "writer1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.35),
            "writer2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer2),
            writer2LusdBalance,
            "writer2 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance,
            "holder1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance,
            "holder1 LUSD balance before exercise"
        );

        // warp to exercise window
        vm.warp(expiryWeeklies[0]);

        _;
    }

    modifier withMediumBackground(uint256 writes) {
        // TODO

        _;
    }

    modifier withComplexBackground() {
        writer1WethBalance = WETHLIKE.balanceOf(writer1);
        writer1LusdBalance = LUSDLIKE.balanceOf(writer1);
        writer2WethBalance = WETHLIKE.balanceOf(writer2);
        writer2LusdBalance = LUSDLIKE.balanceOf(writer2);
        writer3WethBalance = WETHLIKE.balanceOf(writer3);
        writer3LusdBalance = LUSDLIKE.balanceOf(writer3);
        holder1WethBalance = WETHLIKE.balanceOf(holder1);
        holder1LusdBalance = LUSDLIKE.balanceOf(holder1);
        holder2WethBalance = WETHLIKE.balanceOf(holder2);
        holder2LusdBalance = LUSDLIKE.balanceOf(holder2);

        // Given writer1 writes 1.25 options of oti1
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        oti1 = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1700e18, true, 1.25e6
        );
        vm.stopPrank();

        // And writer2 writes 0.25 options of oti1
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeExisting(oti1, 0.25e6);
        vm.stopPrank();

        // And writer1 transfers 0.5 shorts of oti1 to writer3
        vm.prank(writer1);
        clarity.transfer(writer3, oti1 + 1, 0.5e6);

        // And writer1 writes 1 option of oti2
        vm.prank(writer1);
        oti2 = clarity.writeNewCall(
            address(WETHLIKE), address(LUSDLIKE), expiryWeeklies[0], 1750e18, true, 1e6
        );

        // And writer1 writes 1 option of oti1
        vm.prank(writer1);
        clarity.writeExisting(oti1, 1e6);

        // And writer1 transfers 2.25 longs of oti1 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti1, 2.25e6);

        // And writer2 transfers 0.2 longs of oti1 to holder1
        vm.prank(writer2);
        clarity.transfer(holder1, oti1, 0.2e6);

        // And writer2 transfers 0.05 longs of oti1 to holder2
        vm.prank(writer2);
        clarity.transfer(holder2, oti1, 0.05e6);

        // And writer1 transfers 0.95 longs of oti2 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti2, 0.95e6);

        // pre exercise check option balances
        // oti1
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 1),
            1.75e6,
            "oti1 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 2),
            0,
            "oti1 writer1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 1),
            0.25e6,
            "oti1 writer2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 2),
            0,
            "oti1 writer2 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1),
            0,
            "oti1 writer3 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1 + 1),
            0.5e6,
            "oti1 writer3 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1 + 2),
            0,
            "oti1 writer3 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.45e6,
            "oti1 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 1),
            0,
            "oti1 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 2),
            0,
            "oti1 holder1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1),
            0.05e6,
            "oti1 holder2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1 + 1),
            0,
            "oti1 holder2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1 + 2),
            0,
            "oti1 holder2 assigned balance before exercise"
        );

        // oti2
        assertEq(
            clarity.balanceOf(writer1, oti2),
            0.05e6,
            "oti2 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti2 + 1),
            1e6,
            "oti2 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti2 + 2),
            0,
            "oti2 writer1 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti2),
            0.95e6,
            "oti2 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti2 + 1),
            0,
            "oti2 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti2 + 2),
            0,
            "oti2 holder1 assigned balance before exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.25) - (1e18 * 1),
            "writer1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer1),
            writer1LusdBalance,
            "writer1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.25),
            "writer2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer2),
            writer2LusdBalance,
            "writer2 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer3),
            writer3WethBalance,
            "writer3 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer3),
            writer3LusdBalance,
            "writer3 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance,
            "holder1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance,
            "holder1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder2),
            holder2WethBalance,
            "holder2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder2),
            holder2LusdBalance,
            "holder2 LUSD balance before exercise"
        );

        // warp to exercise window
        vm.warp(expiryWeeklies[0]);

        _;
    }
}
