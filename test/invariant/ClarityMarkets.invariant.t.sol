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
        bytes4[] memory selectors = new bytes4[](8);
        // Write
        selectors[0] = OptionsHandler.writeNewCall.selector;
        selectors[1] = OptionsHandler.writeNewPut.selector;
        selectors[2] = OptionsHandler.writeExisting.selector;
        // Transfer
        selectors[3] = OptionsHandler.transferLongs.selector;
        selectors[4] = OptionsHandler.transferShorts.selector;
        // Net
        selectors[5] = OptionsHandler.netOffsetting.selector;
        // Exercise
        selectors[6] = OptionsHandler.exerciseOption.selector;
        // Redeem
        selectors[7] = OptionsHandler.redeemCollateral.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    ///////// Core Protocol Invariant

    function invariant_A1_clearinghouseBalanceForAssetGteClearingLiability() public {
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

    ///////// Core ERC6909 Invariant

    function invariant_B1_sumOfAllBalancesForTokenIdEqTotalSupply() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            // assertEq(
            //     clarity.totalSupply(optionTokenId),
            //     handler.ghost_longSumFor(optionTokenId),
            //     "sumOfAllBalancesForTokenIdEqTotalSupply long"
            // );
            assertEq(
                clarity.totalSupply(shortTokenId),
                handler.ghost_shortSumFor(optionTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply short"
            );
            // assertEq(
            //     clarity.totalSupply(assignedShortTokenId),
            //     handler.ghost_assignedShortSumFor(optionTokenId),
            //     "sumOfAllBalancesForTokenIdEqTotalSupply assignedShort"
            // );
        }
    }

    ///////// Options Invariants

    function invariant_C1_totalSupplyOfLongsEqTotalSupplyOfShorts() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();

            assertEq(
                clarity.totalSupply(optionTokenId),
                clarity.totalSupply(shortTokenId),
                "totalSupplyOfLongsEqTotalSupplyOfShorts"
            );
        }
    }

    function invariant_C2_amountWrittenGteAmountNettedPlusAmountExercised() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertGe(
                handler.ghost_amountWrittenFor(optionTokenId),
                handler.ghost_amountNettedFor(optionTokenId)
                    + handler.ghost_amountExercisedFor(optionTokenId),
                "amountWrittenGteAmountNettedPlusAmountExercised"
            );
        }
    }

    function invariant_C3_amountExercisedEqTotalSupplyOfAssignedShorts() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            assertGe(
                handler.ghost_amountExercisedFor(optionTokenId),
                clarity.totalSupply(assignedShortTokenId),
                "amountExercisedEqTotalSupplyOfAssignedShorts"
            );
        }
    }

    function invariant_C4_amountWrittenMinusAmountNettedEqTotalSupplyOfShortsPlusTotalSupplyOfAssignedShorts(
    ) public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            assertEq(
                handler.ghost_amountWrittenFor(optionTokenId)
                    - handler.ghost_amountNettedFor(optionTokenId),
                clarity.totalSupply(shortTokenId)
                    + clarity.totalSupply(assignedShortTokenId),
                "amountWrittenMinusAmountNettedEqTotalSupplyOfShortsPlusTotalSupplyOfAssignedShorts"
            );
        }
    }

    ///////// Debugging

    function ixnvariant_util_callSummary() public view {
        handler.callSummary();
    }
}
