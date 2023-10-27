// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract NetOffTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function netOff(uint256 _optionTokenId, uint80 optionsAmount)
    //     external
    //     override
    //     returns (uint176 writeAssetNettedOff)

    function test_netOff() public {
        uint256 writerWethBalance = WETHLIKE.balanceOf(writer);
        uint256 writerLusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 1e6);
        vm.stopPrank();

        // pre net off
        // check option balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "writer long balance before net off");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e6, "writer short balance before net off");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "writer assigned balance before net off");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer), writerWethBalance - (1e18 * 1), "writer WETH balance before net off"
        );
        assertEq(LUSDLIKE.balanceOf(writer), writerLusdBalance, "writer LUSD balance before net off");

        // When writer nets off their full position
        clarity.netOff(optionTokenId, 1e6);

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "writer long balance after net off");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 0, "writer short balance after net off");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "writer assigned balance after net off");

        // check asset balances
        assertEq(WETHLIKE.balanceOf(writer), writerWethBalance, "writer WETH balance after net off");
        assertEq(LUSDLIKE.balanceOf(writer), writerLusdBalance, "writer LUSD balance after net off");
    }
}
