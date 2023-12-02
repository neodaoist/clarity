// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseExerciseTest.t.sol";

contract AmericanExerciseTest is BaseExerciseTest {
    /////////

    using LibPosition for uint256;

    /////////
    // function exerciseOptions(uint256 _optionTokenId, uint64 optionsAmount) external

    function test_exerciseOptions() public {
        uint256 writerWethBalance = WETHLIKE.balanceOf(writer);
        uint256 writerLusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 holderWethBalance = WETHLIKE.balanceOf(holder);
        uint256 holderLusdBalance = LUSDLIKE.balanceOf(holder);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 2.25e6
        });
        bool success = clarity.transfer(holder, optionTokenId, 1.15e6);
        require(success);
        vm.stopPrank();

        // pre exercise checks
        assertOptionBalances(
            clarity, writer, optionTokenId, 1.1e6, 2.25e6, 0, "writer before exercise"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 1.15e6, 0, 0, "holder before exercise"
        );
        assertAssetBalance(
            WETHLIKE, writer, writerWethBalance - (1e18 * 2.25), "writer before exercise"
        );
        assertAssetBalance(LUSDLIKE, writer, writerLusdBalance, "writer before exercise");
        assertAssetBalance(WETHLIKE, holder, holderWethBalance, "holder before exercise");
        assertAssetBalance(LUSDLIKE, holder, holderLusdBalance, "holder before exercise");

        // exercise
        vm.warp(FRI1);

        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(optionTokenId, 0.8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity,
            writer,
            optionTokenId,
            1.1e6,
            (2.25e6 * (2.25e6 - 0.8e6)) / 2.25e6,
            (2.25e6 * 0.8e6) / 2.25e6,
            "writer after exercise"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0.35e6, 0, 0, "holder after exercise"
        );
        assertAssetBalance(
            WETHLIKE, writer, writerWethBalance - (1e18 * 2.25), "writer after exercise"
        );
        assertAssetBalance(LUSDLIKE, writer, writerLusdBalance, "writer after exercise");
        assertAssetBalance(
            WETHLIKE, holder, holderWethBalance + (1e18 * 0.8), "holder after exercise"
        );
        assertAssetBalance(
            LUSDLIKE, holder, holderLusdBalance - (1700e18 * 0.8), "holder after exercise"
        );
    }

    // Happy path, Simple background, Scenarios A-F

    function test_exerciseOptions_whenSimpleA_andOneHolderExercisesLessThanWrite1()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 0.1e6);
        vm.stopPrank();

        // Then
        assertOptionBalances(
            clarity,
            writer1,
            oti1,
            0,
            (2.15e6 * (2.5e6 - 0.1e6)) / 2.5e6,
            (2.15e6 * 0.1e6) / 2.5e6,
            "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity,
            writer2,
            oti1,
            0,
            (0.35e6 * (2.5e6 - 0.1e6)) / 2.5e6,
            (0.35e6 * 0.1e6) / 2.5e6,
            "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 2.4e6, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE, holder1, holder1WethBalance + (1e18 * 0.1), "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 0.1),
            "holder1 after exercise"
        );
    }

    function test_exerciseOptions_whenSimpleB_andOneHolderExercisesEqualToWrite1()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.15 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 0.15e6);
        vm.stopPrank();

        // Then
        assertOptionBalances(
            clarity,
            writer1,
            oti1,
            0,
            (2.15e6 * (2.5e6 - 0.15e6)) / 2.5e6,
            (2.15e6 * 0.15e6) / 2.5e6,
            "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity,
            writer2,
            oti1,
            0,
            (0.35e6 * (2.5e6 - 0.15e6)) / 2.5e6,
            (0.35e6 * 0.15e6) / 2.5e6,
            "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 2.35e6, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE,
            holder1,
            holder1WethBalance + (1e18 * 0.15),
            "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 0.15),
            "holder1 after exercise"
        );
    }

    function test_exerciseOptions_whenSimpleC_andOneHolderExercisesLessThanWrite2()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.2 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 0.2e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity,
            writer1,
            oti1,
            0,
            (2.15e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            (2.15e6 * 0.2e6) / 2.5e6,
            "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity,
            writer2,
            oti1,
            0,
            (0.35e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            (0.35e6 * 0.2e6) / 2.5e6,
            "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 2.3e6, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE, holder1, holder1WethBalance + (1e18 * 0.2), "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 0.2),
            "holder1 after exercise"
        );
    }

    function test_exerciseOptions_whenSimpleD_andOneHolderExercisesEqualToWrite2()
        public
        withSimpleBackground
    {
        // When holder1 exercises 0.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 0.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity,
            writer1,
            oti1,
            0,
            (2.15e6 * (2.5e6 - 0.5e6)) / 2.5e6,
            (2.15e6 * 0.5e6) / 2.5e6,
            "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity,
            writer2,
            oti1,
            0,
            (0.35e6 * (2.5e6 - 0.5e6)) / 2.5e6,
            (0.35e6 * 0.5e6) / 2.5e6,
            "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 2e6, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE, holder1, holder1WethBalance + (1e18 * 0.5), "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 0.5),
            "holder1 after exercise"
        );
    }

    function test_exerciseOptions_whenSimpleE_andOneHolderExercisesLessThanWrite3()
        public
        withSimpleBackground
    {
        // When holder1 exercises 1 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 1e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity,
            writer1,
            oti1,
            0,
            (2.15e6 * (2.5e6 - 1e6)) / 2.5e6,
            (2.15e6 * 1e6) / 2.5e6,
            "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity,
            writer2,
            oti1,
            0,
            (0.35e6 * (2.5e6 - 1e6)) / 2.5e6,
            (0.35e6 * 1e6) / 2.5e6,
            "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 1.5e6, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE, holder1, holder1WethBalance + (1e18 * 1), "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 1),
            "holder1 after exercise"
        );
    }

    function test_exerciseOptions_whenSimpleF_andOneHolderExercisesEqualToWrite3()
        public
        withSimpleBackground
    {
        // When holder1 exercises 2.5 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(oti1, 2.5e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity, writer1, oti1, 0, 0, 2.15e6, "oti1 writer1 after exercise"
        );
        assertOptionBalances(
            clarity, writer2, oti1, 0, 0, 0.35e6, "oti1 writer2 after exercise"
        );
        assertOptionBalances(
            clarity, holder1, oti1, 0, 0, 0, "oti1 holder1 after exercise"
        );
        assertAssetBalance(
            WETHLIKE, holder1, holder1WethBalance + (1e18 * 2.5), "holder1 after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder1,
            holder1LusdBalance - (1750e18 * 2.5),
            "holder1 after exercise"
        );
    }

    // TODO complex exercise scenarios

    // function test_exerciseOptions_many_whenComplex_AndOneHolderExercisesAllOnce() public
    // withComplexBackground {
    //     // When holder1 exercises 2.45 options of oti1
    //     vm.startPrank(holder1);
    //     LUSDLIKE.approve(address(clarity), type(uint256).max);
    //     clarity.exerciseOptions(oti1, 2.45e6);
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

    function test_exerciseOptions_upperBounds() public {
        uint256 numWrites = 3000;
        uint256 optionAmountWritten;

        deal(address(LUSDLIKE), holder, 1e30);

        uint256 holderWethBalance = WETHLIKE.balanceOf(holder);
        uint256 holderLusdBalance = LUSDLIKE.balanceOf(holder);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
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
        assertOptionBalances(
            clarity,
            writer,
            optionTokenId,
            0,
            optionAmountWritten,
            0,
            "writer before exercise"
        );
        assertOptionBalances(
            clarity,
            holder,
            optionTokenId,
            optionAmountWritten,
            0,
            0,
            "holder before exercise"
        );

        vm.warp(FRI1 - 1 seconds);
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOptions(optionTokenId, uint64(optionAmountWritten));
        vm.stopPrank();

        // check option balances
        assertOptionBalances(
            clarity,
            writer,
            optionTokenId,
            0,
            0,
            optionAmountWritten,
            "writer after exercise"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0, 0, 0, "holder after exercise"
        );
        assertAssetBalance(
            WETHLIKE,
            holder,
            holderWethBalance + 1e12 * optionAmountWritten,
            "holder after exercise"
        );
        assertAssetBalance(
            LUSDLIKE,
            holder,
            holderLusdBalance - 1700e12 * optionAmountWritten,
            "holder after exercise"
        );
    }

    // Events

    function testEvent_exerciseOptions_OptionsExercised() public withSimpleBackground {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsExercised(holder, oti1, 1.000005e6);

        clarity.exerciseOptions(oti1, 1.000005e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_exerciseOptions_whenExerciseAmountZero() public {
        vm.expectRevert(IOptionErrors.ExerciseAmountZero.selector);

        vm.prank(holder);
        clarity.exerciseOptions(123, 0);
    }

    function testRevert_exerciseOptions_whenOptionDoesNotExist() public {
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, 123)
        );

        vm.prank(holder);
        clarity.exerciseOptions(123, 1e6);
    }

    function testRevert_exerciseOptions_whenOptionTokenIdNotLong() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        uint256 shortTokenId = optionTokenId.longToShort();
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyExerciseLongs.selector, shortTokenId
            )
        );

        clarity.exerciseOptions(shortTokenId, 1e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyExerciseLongs.selector, assignedShortTokenId
            )
        );

        clarity.exerciseOptions(assignedShortTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_exerciseOptions_givenAfterExpiry() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        vm.warp(FRI1 + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionNotWithinExerciseWindow.selector, 1, FRI1
            )
        );

        vm.prank(writer);
        clarity.exerciseOptions(optionTokenId, 1e6);
    }

    function testRevert_exerciseOptions_whenExerciseAmountExceedsLongBalance() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        vm.warp(FRI1 - 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ExerciseAmountExceedsLongBalance.selector, 1.000001e6, 1e6
            )
        );

        vm.prank(writer);
        clarity.exerciseOptions(optionTokenId, 1.000001e6);
    }

    // TODO revert on too much decimal precision
}
