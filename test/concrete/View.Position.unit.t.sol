// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTestSuite.t.sol";

// Views Under Test
import {IOption} from "../../src/interface/option/IOption.sol";
import {IPosition} from "../../src/interface/IPosition.sol";

contract PositionViewTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;

    /////////
    // function tokenType(uint256 tokenId) external view returns (TokenType _tokenType);

    function test_tokenType() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        vm.stopPrank();

        assertEq(
            clarity.tokenType(optionTokenId),
            IPosition.TokenType.LONG,
            "positionTokenType when long"
        );
        assertEq(
            clarity.tokenType(optionTokenId.longToShort()),
            IPosition.TokenType.SHORT,
            "positionTokenType when short"
        );
        assertEq(
            clarity.tokenType(optionTokenId.longToAssignedShort()),
            IPosition.TokenType.ASSIGNED_SHORT,
            "positionTokenType when assigned short"
        );
    }

    // Sad Path

    function testRevert_tokenType_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1750e18,
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );
        uint256 notCreatedOptionTokenId = LibPosition.hashToId(instrumentHash);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, notCreatedOptionTokenId
            )
        );

        // When
        clarity.tokenType(notCreatedOptionTokenId);
    }

    function testRevert_tokenType_whenOptionExistsButInvalidTokenType() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        vm.stopPrank();

        // Then
        vm.expectRevert(stdError.enumConversionError);

        // When
        clarity.tokenType(optionTokenId | 3);
    }

    /////////
    // function position(uint256 optionTokenId)
    //     external
    //     view
    //     returns (Position memory position, int160 magnitude);

    function test_position() public {
        // Given writer1 writes 1 options
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // And writer2 writes 0.25 options
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeExisting(optionTokenId, 0.25e6);
        vm.stopPrank();

        // And writer1 writes 2 options
        vm.prank(writer1);
        clarity.writeExisting(optionTokenId, 2e6);

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

    function test_position_whenTokenTypeIsShort() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 17e6
        });

        // When
        (IPosition.Position memory position, int160 magnitude) =
            clarity.position(LibPosition.longToShort(optionTokenId));
        vm.stopPrank();

        // Then
        assertEq(position.amountLong, 17e6, "amount long");
        assertEq(position.amountShort, 17e6, "amount short");
        assertEq(position.amountAssignedShort, 0, "amount assigned short");
        assertEq(magnitude, 0, "magnitude");
    }

    function test_position_whenTokenTypeIsAssignedShort() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 17e6
        });

        // When
        (IPosition.Position memory position, int160 magnitude) =
            clarity.position(LibPosition.longToAssignedShort(optionTokenId));
        vm.stopPrank();

        // Then
        assertEq(position.amountLong, 17e6, "amount long");
        assertEq(position.amountShort, 17e6, "amount short");
        assertEq(position.amountAssignedShort, 0, "amount assigned short");
        assertEq(magnitude, 0, "magnitude");
    }

    function test_position_writer_givenAssigned() public {
        // Given writer1 writes 0.15 options of oti1
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), type(uint256).max);
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
        WETHLIKE.approve(address(clarity), type(uint256).max);
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

        // And holder1 exercises 0.2 options of oti1
        vm.warp(FRI1 - 1 seconds);

        vm.startPrank(holder1);
        LUSDLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOption(oti1, 0.2e6);
        vm.stopPrank();

        // Then
        // check writer1 position
        vm.prank(writer1);
        (IPosition.Position memory position1, int160 magnitude1) = clarity.position(oti1);

        assertEq(position1.amountLong, 0, "writer1 amount long");
        assertEq(
            position1.amountShort,
            (2.15e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "writer1 amount short"
        );
        assertEq(
            position1.amountAssignedShort,
            (2.15e6 * 0.2e6) / 2.5e6,
            "writer1 amount assigned short"
        );
        assertEq(magnitude1, -1.978e6, "writer1 magnitude");

        // check writer2 position
        vm.prank(writer2);
        (IPosition.Position memory position2, int160 magnitude2) = clarity.position(oti1);

        assertEq(position2.amountLong, 0, "writer2 amount long");
        assertEq(
            position2.amountShort,
            (0.35e6 * (2.5e6 - 0.2e6)) / 2.5e6,
            "writer2 amount short"
        );
        assertEq(
            position2.amountAssignedShort,
            (0.35e6 * 0.2e6) / 2.5e6,
            "writer2 amount assigned short"
        );
        assertEq(magnitude2, -0.322e6, "writer2 magnitude");

        // check holder1 position
        vm.prank(holder1);
        (IPosition.Position memory position3, int160 magnitude3) = clarity.position(oti1);

        assertEq(position3.amountLong, 2.3e6, "holder1 amount long");
        assertEq(position3.amountShort, 0, "holder1 amount short");
        assertEq(position3.amountAssignedShort, 0, "holder1 amount assigned short");
        assertEq(magnitude3, 2.3e6, "holder1 magnitude");

        // check overall market
        assertTotalSupplies(
            clarity, oti1, 2.3e6, 2.3e6, 0.2e6, "total supplies after exercise"
        );
        assertEq(
            magnitude1 + magnitude2,
            magnitude3 * -1,
            "long magnitude mirrors short magnitude"
        );
    }

    // TODO writer givenTransferred

    // TODO writer givenNetted

    // TODO writer givenExercised

    // TODO writer givenRedeemed

    // Sad Paths

    function testRevert_position_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1750e18,
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );
        uint256 notCreatedOptionTokenId = LibPosition.hashToId(instrumentHash);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, notCreatedOptionTokenId
            )
        );

        // When
        clarity.position(notCreatedOptionTokenId);
    }

    function testRevert_position_whenOptionExistsButInvalidTokenType() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });
        vm.stopPrank();

        // Then
        vm.expectRevert(stdError.enumConversionError);

        // When
        clarity.position(optionTokenId | 3);
    }
}
