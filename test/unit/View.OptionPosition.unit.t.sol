// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Views Under Test
import {IPosition} from "../../src/interface//IPosition.sol";

contract OptionPositionViewsTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function position(uint256 optionTokenId)
    //     external
    //     view
    //     returns (Position memory position, int160 magnitude);

    function test_position() public {
        // Given writer1 writes 1 options
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 1e6
        );
        vm.stopPrank();

        // And writer2 writes 0.25 options
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(optionTokenId, 0.25e6);
        vm.stopPrank();

        // And writer1 writes 2 options
        vm.prank(writer1);
        clarity.write(optionTokenId, 2e6);

        // And writer1 transfers 0.5 longs to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, optionTokenId, 0.5e6);

        // Then
        // check writer1 position
        vm.prank(writer1);
        (IPosition.Position memory position, int160 magnitude) =
            clarity.position(optionTokenId);

        assertEq(position.amountLong, 2.5e6, "writer1 amount long");
        assertEq(position.amountShort, 3e6, "writer1 amount short");
        assertEq(position.amountAssignedShort, 0, "writer1 amount assigned short");
        assertEq(magnitude, -0.5e6, "writer1 magnitude");

        // check writer2 position
        vm.prank(writer2);
        (position, magnitude) = clarity.position(optionTokenId);

        assertEq(position.amountLong, 0.25e6, "writer2 amount long");
        assertEq(position.amountShort, 0.25e6, "writer2 amount short");
        assertEq(position.amountAssignedShort, 0, "writer2 amount assigned short");
        assertEq(magnitude, 0, "writer2 magnitude");

        // check holder1 position
        vm.prank(holder1);
        (position, magnitude) = clarity.position(optionTokenId);

        assertEq(position.amountLong, 0.5e6, "holder1 amount long");
        assertEq(position.amountShort, 0, "holder1 amount short");
        assertEq(position.amountAssignedShort, 0, "holder1 amount assigned short");
        assertEq(magnitude, 0.5e6, "holder1 magnitude");
    }

    function test_position_writer_whenAssigned() public withSimpleBackground {
        // When holder1 exercises 0.2 options of oti1
        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        // Then
        // check writer1 position
        vm.prank(writer1);
        (IPosition.Position memory position, int160 magnitude) = clarity.position(oti1);

        assertEq(position.amountLong, 0, "writer1 amount long");
        assertEq(
            position.amountShort,
            (2.15e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "writer1 amount short"
        );
        assertEq(
            position.amountAssignedShort,
            (2.15e6 * 0.2e6) / 2.5e6,
            "writer1 amount assigned short"
        );
        assertEq(magnitude, -2.15e6, "writer1 magnitude");

        // check writer2 position
        vm.prank(writer2);
        (position, magnitude) = clarity.position(oti1);

        assertEq(position.amountLong, 0, "writer2 amount long");
        assertEq(
            position.amountShort,
            (0.35e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "writer2 amount short"
        );
        assertEq(
            position.amountAssignedShort,
            (0.35e6 * 0.2e6) / 2.5e6,
            "writer2 amount assigned short"
        );
        assertEq(magnitude, -0.35e6, "writer2 magnitude");

        // check holder1 position
        vm.prank(holder1);
        (position, magnitude) = clarity.position(oti1);

        assertEq(position.amountLong, 2.3e6, "holder1 amount long");
        assertEq(position.amountShort, 0, "holder1 amount short");
        assertEq(position.amountAssignedShort, 0, "holder1 amount assigned short");
        assertEq(magnitude, 2.3e6, "holder1 magnitude");
    }

    // TODO writer whenNettedOff

    // TODO writer whenRedeemed

    // TODO writer whenExercised

    // Sad Paths

    // TODO

    /////////
    // function positionNettableAmount(uint256 optionTokenId)
    //     external
    //     view
    //     returns (uint64 amount);

    // TODO

    // Sad Paths

    // TODO

    /////////
    // function positionRedeemableAmount(uint256 optionTokenId)
    //     external
    //     view
    //     returns (uint64 amount, uint32 when);

    // TODO

    // Sad Paths

    // TODO
}
