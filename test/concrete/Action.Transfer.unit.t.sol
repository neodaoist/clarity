// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTestSuite.t.sol";

contract TransferTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;

    /////////
    // function transfer(address receiver, uint256 id, uint256 amount)
    //     external
    //     returns (bool);

    function test_transfer_whenLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // pre checks
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "before transfer");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1e6, 1e6, 0, "writer before transfer"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0, 0, 0, "holder before transfer"
        );

        // When
        vm.prank(writer);
        clarity.transfer(holder, optionTokenId, 0.75e6);

        // Then
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "after transfer");
        assertOptionBalances(
            clarity, writer, optionTokenId, 0.25e6, 1e6, 0, "writer after transfer"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0.75e6, 0, 0, "holder after transfer"
        );
    }

    function test_transfer_whenShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // pre checks
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "before transfer");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1e6, 1e6, 0, "writer before transfer"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0, 0, 0, "holder before transfer"
        );

        // When
        vm.prank(writer);
        clarity.transfer(holder, optionTokenId.longToShort(), 0.75e6);

        // Then
        assertTotalSupplies(clarity, optionTokenId, 1e6, 1e6, 0, "after transfer");
        assertOptionBalances(
            clarity, writer, optionTokenId, 1e6, 0.25e6, 0, "writer after transfer"
        );
        assertOptionBalances(
            clarity, holder, optionTokenId, 0, 0.75e6, 0, "holder after transfer"
        );
    }

    // Sad Paths

    function testRevert_transfer_whenOptionDoesNotExist() public {
        // Then
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, 456)
        );

        // When
        vm.prank(writer);
        clarity.transfer(holder, 456, 1e6);
    }

    function testRevert_transfer_whenAssignedShortToken() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.CanOnlyTransferLongOrShort.selector);

        // When
        vm.prank(writer);
        clarity.transfer(holder, optionTokenId.longToAssignedShort(), 1e6);
    }

    function testRevert_transfer_whenShort_givenOptionIsAssigned() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1700e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        // warp to expiry
        vm.warp(FRI1);

        // exercise
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.exerciseOption(optionTokenId, 0.000001e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.CanOnlyTransferShortIfUnassigned.selector);

        // When
        vm.prank(writer);
        clarity.transfer(holder, optionTokenId.longToShort(), 0.5e6);
    }

    /////////
    // function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
    //     external
    //     returns (bool);

    // TODO
}
