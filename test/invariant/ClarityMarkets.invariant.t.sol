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
        bytes4[] memory selectors = new bytes4[](6);
        // Write
        selectors[0] = OptionsHandler.writeNewCall.selector;
        selectors[1] = OptionsHandler.writeNewPut.selector;
        selectors[2] = OptionsHandler.writeExisting.selector;
        // Transfer
        selectors[3] = OptionsHandler.transferLongs.selector;
        selectors[4] = OptionsHandler.transferShorts.selector;
        // Exercise
        selectors[5] = OptionsHandler.exerciseLongs.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    ///////// Core Protocol Invariant

    function invariant_A1_clearinghouseBalanceForAssetGteClearingLiability() public {
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

    ///////// Core ERC6909 Invariant

    function invariant_B1_sumOfAllBalancesForTokenIdEqTotalSupply() public {
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

    ///////// Options Invariants

    function invariant_C1_totalSupplyOfLongsEqTotalSupplyOfShorts() public {
        console2.log("invariantC1_totalSupplyOfLongsEqTotalSupplyOfShorts");

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

    function invariant_C2_amountWrittenGteAmountNettedOffPlusAmountExercised() public {
        console2.log("invariantC2_amountWrittenGteAmountNettedOffPlusAmountExercised");

        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertGe(
                handler.ghost_amountWrittenFor(optionTokenId),
                handler.ghost_amountNettedOffFor(optionTokenId)
                    + handler.ghost_amountExercisedFor(optionTokenId),
                "amountWrittenGteAmountNettedOffPlusAmountExercised"
            );
        }
    }

    function invariant_C3_amountExercisedEqTotalSupplyOfAssignedShorts() public {
        console2.log("invariantC3_amountExercisedEqTotalSupplyOfAssignedShorts");

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

    function invariant_C4_amountWrittenMinusAmountNettedOffEqTotalSupplyOfShortsPlusTotalSupplyOfAssignedShorts(
    ) public {
        console2.log(
            "invariantC4_amountWrittenMinusAmountNettedOffEqTotalSupplyOfShortsPlusTotalSupplyOfAssignedShorts"
        );

        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            assertEq(
                handler.ghost_amountWrittenFor(optionTokenId)
                    - handler.ghost_amountNettedOffFor(optionTokenId),
                clarity.totalSupply(shortTokenId)
                    + clarity.totalSupply(assignedShortTokenId),
                "amountWrittenMinusAmountNettedOffEqTotalSupplyOfShortsPlusTotalSupplyOfAssignedShorts"
            );
        }
    }

    ///////// Debugging

    function invariant_util_callSummary() public view {
        handler.callSummary();
    }
}
