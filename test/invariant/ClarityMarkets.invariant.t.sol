// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {Handler} from "../util/Handler.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract ClarityMarketsInvariantTest is Test {
    /////////

    ClarityMarkets private clarity;
    Handler private handler;

    function setUp() public {
        // deploy DCP
        clarity = new ClarityMarkets();

        // setup handler
        handler = new Handler(clarity);
    }

    function invariantA_clearinghouseBalanceForAssetGteClearingLiability() public {
    }

    function invariantB1_sumOfAllBalancesForTokenIdEqTotalSupply() public {
        // uint256 sumOfLongBalances = handler.reduceActors(0, this.accumulateLongBalances);
        // uint256 sumOfShortBalances = handler.reduceActors(0, this.accumulateShortBalances);
        // uint256 sumOfAssignedShortBalances = handler.reduceActors(0, this.accumulateAssignedShortBalances);
    }

    function invariantC1_clearingLiabilityForAssetEqSumOfLongsShortsAndAssignedShortsLiability(
    ) public {}

    function invariantC1_totalSupplyOfLongsForOptionEqTotalSupplyOfShorts() public {}

    ///////// Accumulators

    // function accumulateBalances(uint256 balance, address caller, uint256 tokenId) external view returns (uint256) {
    //     return balance + clarity.balanceOf(caller, tokenId);
    // }

    ///////// Assertions

    // function assertAccountBalanceLteTotalSupply(address account) external {
    //     assertLe(weth.balanceOf(account), weth.totalSupply());
    // }
}
