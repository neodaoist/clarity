// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {OptionsHandler} from "../util/OptionsHandler.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Interfaces
import {IOption} from "../../src/interface/option/IOption.sol";

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
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = OptionsHandler.writeNewCall.selector;
        selectors[1] = OptionsHandler.writeNewPut.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function invariantA1_clearinghouseBalanceForAssetGteClearingLiability() public {
        console2.log("invariantA1_clearinghouseBalanceForAssetGteClearingLiability");

        for (uint256 i = 0; i < handler.baseAssetsCount(); i++) {
            IERC20 baseAsset = handler.baseAssetAt(i);
            assertGe(
                baseAsset.balanceOf(address(clarity)),
                handler.ghost_clearingLiabilityFor(address(baseAsset)),
                "clearinghouseBalanceForAssetGteClearingLiability baseAsset"
            );
        }

        for (uint256 i = 0; i < handler.quoteAssetsCount(); i++) {
            IERC20 quoteAsset = handler.quoteAssetAt(i);
            assertGe(
                quoteAsset.balanceOf(address(clarity)),
                handler.ghost_clearingLiabilityFor(address(quoteAsset)),
                "clearinghouseBalanceForAssetGteClearingLiability quoteAsset"
            );
        }
    }

    function invariantB1_sumOfAllBalancesForTokenIdEqTotalSupply() public {
        console2.log("invariantB1_sumOfAllBalancesForTokenIdEqTotalSupply");

        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            assertEq(
                clarity.totalSupply(optionTokenId),
                handler.ghost_longSumFor(optionTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply long"
            );
            assertEq(
                clarity.totalSupply(shortTokenId),
                handler.ghost_shortSumFor(optionTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply short"
            );
            assertEq(
                clarity.totalSupply(assignedShortTokenId),
                handler.ghost_assignedShortSumFor(optionTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply assignedShort"
            );
        }
    }
}
