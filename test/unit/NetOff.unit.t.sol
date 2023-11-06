// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract NetOffTest is BaseClarityMarketsTest {
    /////////

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
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 1e6
        );
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

    // TODO

    // Sad Paths

    function testRevert_netOff_whenOptionDoesNotExist() public {
        uint256 nonExistentOptionTokenId = 456;

        vm.prank(writer);
        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionDoesNotExist.selector, nonExistentOptionTokenId
            )
        );

        clarity.netOff(nonExistentOptionTokenId, 1e6);
    }

    function testRevert_netOff_whenDontHoldSufficientLongs() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 1e6
        );
        clarity.transfer(holder, optionTokenId, 0.1e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.InsufficientLongBalance.selector, optionTokenId, 1e6
            )
        );

        clarity.netOff(optionTokenId, 1e6);
        vm.stopPrank();
    }

    function testRevert_netOff_whenDontHoldSufficientShorts() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 1e6
        );
        clarity.transfer(holder, LibToken.longToShort(optionTokenId), 0.1e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.InsufficientShortBalance.selector, optionTokenId, 1e6
            )
        );

        clarity.netOff(optionTokenId, 1e6);
        vm.stopPrank();
    }
}
