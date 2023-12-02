// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTest.t.sol";

contract SkimTest is BaseUnitTest {
    /////////

    /////////
    // function skimmable(address asset) external view returns (uint256 amount);

    function test_skimmable() public {
        // Given 10 WETH-FRAX put options with strike 2050 have been written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 10
        });
        vm.stopPrank();

        // And 100 FRAX has been sent directly to the clearinghouse
        vm.prank(holder);
        FRAXLIKE.transfer(address(clarity), 100e18);

        // When I check how much FRAX is skimmable
        uint256 skimmable = clarity.skimmable(address(FRAXLIKE));

        // Then I should see 100 FRAX is skimmable
        assertEq(skimmable, 100e18, "skimmable");
    }

    function test_skimmable_givenNothingToSkim() public {
        // Given 10 WETH-FRAX put options with strike 2050 have been written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 10
        });
        vm.stopPrank();

        // When I check how much FRAX is skimmable
        uint256 skimmable = clarity.skimmable(address(FRAXLIKE));

        // Then I should see 0 FRAX is skimmable
        assertEq(skimmable, 0, "skimmable");
    }

    function test_skimmable_whenManyAssets() public {
        // Given some options are written, collateralized by WETH, FRAX, WBTC, and USDC
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        WBTCLIKE.approve(address(clarity), type(uint256).max);
        USDCLIKE.approve(address(clarity), type(uint256).max);
        oti1 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 0.0275e6
        });
        oti2 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 17e6
        });
        oti3 = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2000e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        oti4 = clarity.writeNewCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 38_000e18,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        oti5 = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 2000e6,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        // And there is an extra amount sent to the clearinghouse for each asset
        vm.startPrank(holder);
        WETHLIKE.transfer(address(clarity), 100e18);
        FRAXLIKE.transfer(address(clarity), 99e18);
        WBTCLIKE.transfer(address(clarity), 98e8);
        USDCLIKE.transfer(address(clarity), 97e6);
        vm.stopPrank();

        // When I check how much of each asset is skimmable
        // Then I should see the correct amount
        assertEq(clarity.skimmable(address(WETHLIKE)), 100e18, "WETH skimmable");
        assertEq(clarity.skimmable(address(FRAXLIKE)), 99e18, "FRAX skimmable");
        assertEq(clarity.skimmable(address(WBTCLIKE)), 98e8, "WBTC skimmable");
        assertEq(clarity.skimmable(address(USDCLIKE)), 97e6, "USDC skimmable");
    }

    /////////
    // function skim(address asset) external returns (uint256 amount);

    function test_skim() public {
        // Given 10 WETH-FRAX put options with strike 2050 have been written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 10
        });
        vm.stopPrank();

        // And 100 FRAX has been sent directly to the clearinghouse
        vm.prank(holder);
        FRAXLIKE.transfer(address(clarity), 100e18);

        // And my FRAX balance is X
        uint256 fraxBalance = FRAXLIKE.balanceOf(writer2);

        // When I skim FRAX
        vm.prank(writer2);
        uint256 amountSkimmed = clarity.skim(address(FRAXLIKE));

        // Then I should see 100 FRAX has been skimmed
        assertEq(amountSkimmed, 100e18, "amountSkimmed");

        // And my FRAX balance should be X + 100
        assertEq(FRAXLIKE.balanceOf(writer2), fraxBalance + 100e18, "fraxBalance");
    }

    // Sad Paths

    function testRevert_skim_givenNothingToSkim() public {
        // Given 10 WETH-FRAX put options with strike 2050 have been written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 10
        });
        vm.stopPrank();

        // Then I should see a NothingSkimmable error, with the FRAX address
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.NothingSkimmable.selector, address(FRAXLIKE)
            )
        );

        // When I skim FRAX
        vm.prank(writer2);
        clarity.skim(address(FRAXLIKE));
    }
}
