// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

contract NetOffTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;

    /////////
    // function netOff(uint256 _optionTokenId, uint64 optionsAmount)
    //     external
    //     override
    //     returns (uint128 writeAssetNettedOff);

    function test_netOff() public {
        uint256 writerWethBalance = WETHLIKE.balanceOf(writer);
        uint256 writerLusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // pre net off
        assertOptionBalances(writer, optionTokenId, 1e6, 1e6, 0, "writer before net off");
        assertAssetBalance(
            writer, WETHLIKE, writerWethBalance - (1e18 * 1), "writer before net off"
        );
        assertAssetBalance(writer, LUSDLIKE, writerLusdBalance, "writer before net off");

        writerWethBalance = WETHLIKE.balanceOf(writer);
        writerLusdBalance = LUSDLIKE.balanceOf(writer);

        // When writer nets off their full position
        vm.prank(writer);
        uint128 writeAssetNettedOff = clarity.netOff(optionTokenId, 1e6);

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "writer after net off");
        assertAssetBalance(
            writer,
            WETHLIKE,
            writerWethBalance + writeAssetNettedOff,
            "writer after net off"
        );
        assertAssetBalance(writer, LUSDLIKE, writerLusdBalance, "writer after net off");
    }

    // TODO add more

    // Events

    function testEvent_netOff_OptionsNettedOff() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        vm.expectEmit(true, true, true, true);
        emit IOptionEvents.OptionsNettedOff(writer, optionTokenId, 0.999998e6);

        clarity.netOff(optionTokenId, 0.999998e6);
    }

    // Sad Paths

    function testRevert_netOff_whenAmountZero() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 1750e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        vm.expectRevert(IOptionErrors.NetOffAmountZero.selector);

        clarity.netOff(optionTokenId, 0);
        vm.stopPrank();
    }

    function testRevert_netOff_whenOptionDoesNotExist() public {
        uint256 nonExistentOptionTokenId = 456;

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, nonExistentOptionTokenId
            )
        );

        vm.prank(writer);
        clarity.netOff(nonExistentOptionTokenId, 1e6);
    }

    function testRevert_netOff_whenTokenTypeIsAssignedShort() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.CanOnlyCallNetOffForLongs.selector, assignedShortTokenId
            )
        );

        clarity.netOff(assignedShortTokenId, 1e6);
    }

    function testRevert_netOff_givenOptionIsExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            expiry: FRI1,
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });

        vm.warp(FRI1 + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector, optionTokenId, FRI1
            )
        );

        clarity.netOff(optionTokenId, 1e6);
    }

    function testRevert_netOff_givenDontHoldSufficientLongs() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        clarity.transfer(holder, optionTokenId, 0.1e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientLongBalance.selector, optionTokenId, 1e6
            )
        );

        clarity.netOff(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_netOff_givenDontHoldSufficientShorts() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        clarity.transfer(holder, LibPosition.longToShort(optionTokenId), 0.1e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientShortBalance.selector, optionTokenId, 1e6
            )
        );

        clarity.netOff(optionTokenId, 1e6);
        vm.stopPrank();
    }
}
