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

    using LibPosition for uint256;

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
            uint256 shortTokenId = longTokenId.longToShort();
            uint256 assignedShortTokenId = longTokenId.longToAssignedShort();

            assertEq(
                clarity.totalSupply(longTokenId),
                handler.ghost_longSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply long"
            );
            assertEq(
                clarity.totalSupply(shortTokenId),
                handler.ghost_shortSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply short"
            );
            assertEq(
                clarity.totalSupply(assignedShortTokenId),
                handler.ghost_assignedShortSumFor(longTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply assignedShort"
            );
        }
    }

    // function invariantC1_clearingLiabilityForAssetEqSumOfLongsShortsAndAssignedShortsLiability(
    // ) public {}

    // function invariantC1_totalSupplyOfLongsForOptionEqTotalSupplyOfShorts() public {}
}
