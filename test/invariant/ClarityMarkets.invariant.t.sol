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
        // TODO batchWrite
        // Transfer
        selectors[3] = OptionsHandler.transferLongs.selector;
        selectors[4] = OptionsHandler.transferShorts.selector;
        // Net
        selectors[5] = OptionsHandler.netOffsetting.selector;
        // Exercise
        selectors[6] = OptionsHandler.exerciseOption.selector;
        // Redeem
        selectors[7] = OptionsHandler.redeemCollateral.selector;
        // Skim
        // TODO skim

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

    ///////// User Balance Invariants

    function invariant_B1_totalSupplyForTokenIdEqSumOfAllBalances() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            // long token type
            IOption.Option memory option = clarity.option(optionTokenId);
            if (block.timestamp <= option.expiry) {
                assertEq(
                    clarity.totalSupply(optionTokenId),
                    handler.ghost_longSumFor(optionTokenId),
                    "sumOfAllBalancesForTokenIdEqTotalSupply long, before expiry"
                );
            } else {
                assertEq(
                    clarity.totalSupply(optionTokenId),
                    0,
                    "sumOfAllBalancesForTokenIdEqTotalSupply long, after expiry"
                );
            }

            // short token type
            assertApproxEqAbs(
                clarity.totalSupply(shortTokenId),
                handler.ghost_shortSumFor(optionTokenId),
                1,
                "sumOfAllBalancesForTokenIdEqTotalSupply short"
            );

            // assigned short token type
            assertEq(
                clarity.totalSupply(assignedShortTokenId),
                handler.ghost_assignedShortSumFor(optionTokenId),
                "sumOfAllBalancesForTokenIdEqTotalSupply assignedShort"
            );
        }
    }

    ///////// Options Supply and State Invariants

    // TODO replace ghost state checks with option state checks

    function invariant_C1_totalSupplyOfLongsEqTotalSupplyOfShorts() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();

            IOption.Option memory option = clarity.option(optionTokenId);
            if (block.timestamp <= option.expiry) {
                assertEq(
                    clarity.totalSupply(optionTokenId),
                    clarity.totalSupply(shortTokenId),
                    "totalSupplyOfLongsEqTotalSupplyOfShorts, before expiry"
                );
            } else {
                assertEq(
                    clarity.totalSupply(optionTokenId),
                    0,
                    "totalSupplyOfLongsEqTotalSupplyOfShorts, after expiry"
                );
            }
        }
    }

    function invariant_C2_totalSupplyOfShortsEqWSubNSubXSubRMulProportionUnassigned()
        public
    {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();

            uint256 writtenSubNetted = handler.ghost_amountWrittenFor(optionTokenId)
                - handler.ghost_amountNettedFor(optionTokenId);

            assertEq(
                clarity.totalSupply(shortTokenId),
                writtenSubNetted - handler.ghost_amountExercisedFor(optionTokenId)
                    - (
                        (
                            handler.ghost_amountRedeemedFor(optionTokenId)
                                * (
                                    writtenSubNetted
                                        - handler.ghost_amountExercisedFor(optionTokenId)
                                )
                        ) / writtenSubNetted
                    ),
                "totalSupplyOfShortsEqWSubNSubXSubRMulProportionUnassigned"
            );
        }
    }

    function invariant_C3_totalSupplyOfAssignedShortsEqXSubRMulProportionAssigned()
        public
    {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            uint256 writtenSubNetted = handler.ghost_amountWrittenFor(optionTokenId)
                - handler.ghost_amountNettedFor(optionTokenId);

            assertEq(
                clarity.totalSupply(assignedShortTokenId),
                handler.ghost_amountExercisedFor(optionTokenId)
                    - (
                        (
                            handler.ghost_amountRedeemedFor(optionTokenId)
                                * handler.ghost_amountExercisedFor(optionTokenId)
                        ) / writtenSubNetted
                    ),
                "totalSupplyOfAssignedShortsEqXSubRMulProportionAssigned"
            );
        }
    }

    function invariant_C4_amountWrittenGteNAddXAddR() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertGe(
                handler.ghost_amountWrittenFor(optionTokenId),
                handler.ghost_amountNettedFor(optionTokenId)
                    + handler.ghost_amountExercisedFor(optionTokenId)
                    + handler.ghost_amountRedeemedFor(optionTokenId),
                "amountWrittenGteNAddXAddR"
            );
        }
    }

    function invariant_C5_amountNettedLteW() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertLe(
                handler.ghost_amountNettedFor(optionTokenId),
                handler.ghost_amountWrittenFor(optionTokenId),
                "amountNettedLteW"
            );
        }
    }

    function invariant_C6_amountExercisedLteWSubN() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertLe(
                handler.ghost_amountExercisedFor(optionTokenId),
                handler.ghost_amountWrittenFor(optionTokenId)
                    - handler.ghost_amountNettedFor(optionTokenId),
                "amountExercisedLteWSubN"
            );
        }
    }

    function invariant_C7_amountRedeemedLteWSubN() public {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);

            assertLe(
                handler.ghost_amountRedeemedFor(optionTokenId),
                handler.ghost_amountWrittenFor(optionTokenId)
                    - handler.ghost_amountNettedFor(optionTokenId),
                "amountRedeemedLteWSubN"
            );
        }
    }

    function invariant_C8_amountWrittenSubNSubREqTotalSupplyOfShortsAddAssignedShorts()
        public
    {
        for (uint256 i = 0; i < handler.optionsCount(); i++) {
            uint256 optionTokenId = handler.optionTokenIdAt(i);
            uint256 shortTokenId = optionTokenId.longToShort();
            uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

            assertEq(
                handler.ghost_amountWrittenFor(optionTokenId)
                    - handler.ghost_amountNettedFor(optionTokenId)
                    - handler.ghost_amountRedeemedFor(optionTokenId),
                clarity.totalSupply(shortTokenId)
                    + clarity.totalSupply(assignedShortTokenId),
                "amountWrittenSubNSubREqTotalSupplyOfShortsAddAssignedShorts"
            );
        }
    }

    ///////// Logs

    function invariant_util_callSummary() public view {
        handler.callSummary();
    }
}
