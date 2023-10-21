// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract WriteTest is BaseClarityMarketsTest {
    /////////

    function test_writeCall() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), 1e9, address(LUSDLIKE), 1700e9, americanExWeeklies[0], 1e9
        );

        assertEq(clarity.balanceOf(writer, optionTokenId), 1e9, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e9, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 1e9, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e9 * 1e9), "WETH balance after write");
        assertEq(
            LUSDLIKE.balanceOf(writer), lusdBalance - (1700e9 * 1e9), "LUSD balance after write"
        );
    }
}
