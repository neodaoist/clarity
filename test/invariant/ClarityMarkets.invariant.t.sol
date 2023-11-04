// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {OptionsHandler} from "../util/OptionsHandler.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract ClarityMarketsInvariantTest is Test {
    /////////

    using LibToken for uint256;

    ClarityMarkets private clarity;
    OptionsHandler private handler;

    function setUp() public {
        // deploy DCP
        clarity = new ClarityMarkets();

        // setup handler
        handler = new OptionsHandler(clarity);

        // target contracts
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = OptionsHandler.writeNewCall.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    // function invariantA_clearinghouseBalanceForAssetGteClearingLiability() public {
    // }

    function invariantB1_sumOfAllBalancesForTokenIdEqTotalSupply() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 longTokenId = handler.options()[i];

            assertEq(
                clarity.totalSupply(longTokenId),
                handler.ghost_longSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply long"
            );
            assertEq(
                clarity.totalSupply(longTokenId.longToShort()),
                handler.ghost_shortSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply short"
            );
            assertEq(
                clarity.totalSupply(longTokenId.longToAssignedShort()),
                handler.ghost_assignedShortSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply assignedShort"
            );
        }
    }

    // uint256 sumOfLongBalances = handler.reduceActors(0, this.accumulateLongBalances);
    // uint256 sumOfShortBalances = handler.reduceActors(0, this.accumulateShortBalances);
    // uint256 sumOfAssignedShortBalances = handler.reduceActors(0, this.accumulateAssignedShortBalances);

    // function invariantC1_clearingLiabilityForAssetEqSumOfLongsShortsAndAssignedShortsLiability(
    // ) public {}

    // function invariantC1_totalSupplyOfLongsForOptionEqTotalSupplyOfShorts() public {}

    ///////// Accumulators

    // function accumulateBalances(uint256 balance, address caller, uint256 tokenId) external view returns (uint256) {
    //     return balance + clarity.balanceOf(caller, tokenId);
    // }

    ///////// Assertions

    // function assertAccountBalanceLteTotalSupply(address account) external {
    //     assertLe(weth.balanceOf(account), weth.totalSupply());
    // }
}
