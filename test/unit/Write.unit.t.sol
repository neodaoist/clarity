// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../BaseClarityMarkets.t.sol";

contract WriteTest is BaseClarityMarketsTest {
    /////////

    function test_writeCall() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), 1e12, address(LUSDLIKE), 1700e12, americanExWeeklies[0], 1e6
        );
        vm.stopPrank();

        assertEq(clarity.balanceOf(writer, optionTokenId), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 1e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_zero() public {
        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), 1e12, address(LUSDLIKE), 1700e12, americanExWeeklies[0], 0
        );

        // TODO assert that the Option exists

        // no change
        assertEq(clarity.balanceOf(writer, optionTokenId), 0, "long balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 1), 0, "short balance");
        assertEq(clarity.balanceOf(writer, optionTokenId + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance, "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");
    }

    function test_writeCall_many() public {
        // write WETH-LUSD x3, WBTC-LUSD, WETH-USDC

        // standardized scalar
        // 1e18 WETH = 1 option, so 1e-6 options is 1e12 WETH
        // 1e8 WTBC = 1 option, so 1e-6 options is 1e2 WBTC
        // 1e18 LUSD = 1 option, so 1e-6 options is 1e12 LUSD
        // 1e6 USDC = 1 option, so 1e-6 options is 1 USDC

        uint256 wethBalance = WETHLIKE.balanceOf(writer);
        uint256 wbtcBalance = WBTCLIKE.balanceOf(writer);
        uint256 lusdBalance = LUSDLIKE.balanceOf(writer);
        uint256 usdcBalance = USDCLIKE.balanceOf(writer);

        // WETH-LUSD 1
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 oti1 = clarity.writeCall(
            address(WETHLIKE), 1e12, address(LUSDLIKE), 1700e12, americanExWeeklies[0], 0.0275e6
        );
        vm.stopPrank();

        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance 1");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 0.0275e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 2
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti2 = clarity.writeCall(
            address(WETHLIKE), 1e12, address(LUSDLIKE), 1750e12, americanExWeeklies[0], 17e6
        );

        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance 2");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 17e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-LUSD 3
        wethBalance = WETHLIKE.balanceOf(writer);
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti3 = clarity.writeCall(
            address(WETHLIKE), 2, address(LUSDLIKE), 1700e12, americanExWeeklies[1], 1e6
        );

        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance 3");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (2 * 1e6), "WETH balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WBTC-LUSD
        lusdBalance = LUSDLIKE.balanceOf(writer);

        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleAssetAmount(WBTCLIKE, STARTING_BALANCE));
        uint256 oti4 = clarity.writeCall(
            address(WBTCLIKE), 1e3, address(LUSDLIKE), 20_000e12, americanExWeeklies[0], 10e6
        );
        vm.stopPrank();

        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance 4");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
        assertEq(WBTCLIKE.balanceOf(writer), wbtcBalance - (1e3 * 10e6), "WBTC balance after write");
        assertEq(LUSDLIKE.balanceOf(writer), lusdBalance, "LUSD balance after write");

        // WETH-USDC
        wethBalance = WETHLIKE.balanceOf(writer);

        vm.prank(writer);
        uint256 oti5 = clarity.writeCall(
            address(WETHLIKE), 1e12, address(LUSDLIKE), 1800e6, americanExWeeklies[0], 1e6
        );

        assertEq(clarity.balanceOf(writer, oti5), 1e6, "long balance 5");
        assertEq(clarity.balanceOf(writer, oti5 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti5 + 2), 0, "assigned balance");
        assertEq(WETHLIKE.balanceOf(writer), wethBalance - (1e12 * 1e6), "WETH balance after write");
        assertEq(USDCLIKE.balanceOf(writer), usdcBalance, "USDC balance after write");

        // check previous option balances did not change
        assertEq(clarity.balanceOf(writer, oti1), 0.0275e6, "long balance final");
        assertEq(clarity.balanceOf(writer, oti1 + 1), 0.0275e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti1 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti2), 17e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti2 + 1), 17e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti2 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti3), 1e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti3 + 1), 1e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti3 + 2), 0, "assigned balance");
        assertEq(clarity.balanceOf(writer, oti4), 10e6, "long balance");
        assertEq(clarity.balanceOf(writer, oti4 + 1), 10e6, "short balance");
        assertEq(clarity.balanceOf(writer, oti4 + 2), 0, "assigned balance");
    }
}
