// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "./BaseUnitTestSuite.t.sol";

abstract contract BaseExerciseUnitTestSuite is BaseUnitTestSuite {
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
        oti1 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 0.15e6
        });
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
        vm.warp(FRI1);

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
        oti1 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1.25e6
        });
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
        oti2 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

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
        vm.warp(FRI1);

        _;
    }
}
