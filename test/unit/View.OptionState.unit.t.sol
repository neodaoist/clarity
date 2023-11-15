// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Views Under Test
import {IOptionState} from "../../src/interface/option/IOptionState.sol";

contract OptionStateViewsTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function openInterest(uint256 optionTokenId) external view returns (uint64 amount);

    function test_openInterest_whenWritten() public withSimpleBackground {
        assertEq(clarity.openInterest(oti1), 2.5e6, "open interest");
    }

    function test_openInterest_whenExercised() public withSimpleBackground {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        assertEq(clarity.openInterest(oti1), 2.3e6, "open interest");
    }

    // TODO more

    // Sad Paths

    // TODO

    /////////
    // function remainingWritableAmount(uint256 optionTokenId)
    //     external
    //     view
    //     returns (uint64 amount);

    function test_remainingWritableAmount_whenNoneWritten() public {
        vm.startPrank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 0
        );
        vm.stopPrank();

        assertEq(
            clarity.remainingWriteableAmount(optionTokenId),
            clarity.MAXIMUM_WRITABLE(),
            "maximum writable when none written"
        );
    }

    function test_remainingWritableAmount_whenSomeWritten() public {
        uint64 amountWritten = 10.000001e6;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            amountWritten
        );
        vm.stopPrank();

        assertEq(
            clarity.remainingWriteableAmount(optionTokenId),
            clarity.MAXIMUM_WRITABLE() - amountWritten,
            "maximum writable when some written"
        );
    }

    function test_remainingWritableAmount_whenMostWritten() public {
        uint64 amountWritten = (clarity.MAXIMUM_WRITABLE() * 4) / 5;

        vm.startPrank(writer);
        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 1e27));
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 1e27));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            amountWritten
        );
        vm.stopPrank();

        assertEq(
            clarity.remainingWriteableAmount(optionTokenId),
            clarity.MAXIMUM_WRITABLE() - amountWritten,
            "maximum writable when some written"
        );
    }

    function test_remainingWritableAmount_whenAllWritten() public {
        vm.startPrank(writer);

        deal(address(WETHLIKE), writer, scaleUpAssetAmount(WETHLIKE, 1e27));
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, 1e27));
        deal(address(LUSDLIKE), writer, scaleUpAssetAmount(LUSDLIKE, 1e27));
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, 1e27));

        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1700e18,
            clarity.MAXIMUM_WRITABLE()
        );

        // even after netting off or exercising, remaining writable does not change
        clarity.netOff(optionTokenId, 100e6);

        vm.warp(americanExWeeklies[0][0]);

        clarity.exercise(optionTokenId, 100e6);

        vm.stopPrank();

        assertEq(
            clarity.remainingWriteableAmount(optionTokenId),
            0,
            "maximum writable when some written"
        );
    }

    // Sad Paths

    // TODO
}
