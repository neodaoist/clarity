// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTest.t.sol";

contract SkimFuzzTest is BaseUnitTest {
    /////////

    /////////
    // function skimmable(address asset) external view returns (uint256 amount);

    function testFuzz_skimmable(
        uint256 strike,
        uint256 amountToWrite,
        uint256 amountSkimmable
    ) public {
        // bind fuzz inputs
        strike = bound(strike, clarity.MINIMUM_STRIKE(), clarity.MAXIMUM_STRIKE());
        amountToWrite = bound(amountToWrite, 1, clarity.MAXIMUM_WRITABLE());
        amountSkimmable =
            bound(amountSkimmable, 1, type(uint256).max - (strike * amountToWrite));

        // deal sufficient FRAX
        deal(address(FRAXLIKE), writer, strike * amountToWrite);
        deal(address(FRAXLIKE), holder, amountSkimmable);

        // Given {amountToWrite} WETH-FRAX put options with strike {strike} have been
        // written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: strike,
            allowEarlyExercise: true,
            optionAmount: uint64(amountToWrite)
        });
        vm.stopPrank();

        // And {amountSkimmable} FRAX has been sent directly to the clearinghouse
        vm.prank(holder);
        FRAXLIKE.transfer(address(clarity), amountSkimmable);

        // When I check how much FRAX is skimmable
        uint256 skimmable = clarity.skimmable(address(FRAXLIKE));

        // Then I should see amountSkimmable FRAX is skimmable
        assertEq(skimmable, amountSkimmable, "skimmable");
    }

    /////////
    // function skim(address asset) external returns (uint256 amount);

    function testFuzz_skim(uint256 strike, uint256 amountToWrite, uint256 amountSkimmable)
        public
    {
        // bind fuzz inputs
        uint256 fraxBalance = FRAXLIKE.balanceOf(writer2);
        strike = bound(strike, clarity.MINIMUM_STRIKE(), clarity.MAXIMUM_STRIKE());
        amountToWrite = bound(amountToWrite, 1, clarity.MAXIMUM_WRITABLE());
        amountSkimmable = bound(
            amountSkimmable, 1, type(uint256).max - (strike * amountToWrite) - fraxBalance
        );

        // deal sufficient FRAX
        deal(address(FRAXLIKE), writer, strike * amountToWrite);
        deal(address(FRAXLIKE), holder, amountSkimmable);

        // Given {amountToWrite} WETH-FRAX put options with strike {strike} have been
        // written
        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI2,
            strike: strike,
            allowEarlyExercise: true,
            optionAmount: uint64(amountToWrite)
        });
        vm.stopPrank();

        // And {amountSkimmable} FRAX has been sent directly to the clearinghouse
        vm.prank(holder);
        FRAXLIKE.transfer(address(clarity), amountSkimmable);

        // And my FRAX balance is X (set earlier, during fuzz setup)

        // When I skim FRAX
        vm.prank(writer2);
        uint256 amountSkimmed = clarity.skim(address(FRAXLIKE));

        // Then I should see {amountSkimmable} FRAX has been skimmed
        assertEq(amountSkimmed, amountSkimmable, "amountSkimmed");

        // And my FRAX balance should be X + {amountSkimmable}
        assertEq(
            FRAXLIKE.balanceOf(writer2), fraxBalance + amountSkimmable, "fraxBalance"
        );
    }
}
