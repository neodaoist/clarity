// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {OptionsHandler} from "../util/OptionsHandler.sol";

// Test Fixture
import "../BaseClarityTest.t.sol";

// Interfaces
import {IOption} from "../../src/interface/option/IOption.sol";

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract ClarityMarketsInvariantTest is BaseClarityTest {
    /////////

    using LibPosition for uint256;

    /////////

    OptionsHandler private handler;

    function setUp() public override {
        super.setUp();

        // setup handler
        handler = new OptionsHandler(clarity, baseAssets, quoteAssets);

        // target contracts
        bytes4[] memory selectors = new bytes4[](6);
        // Write
        selectors[0] = OptionsHandler.writeNew.selector;
        selectors[1] = OptionsHandler.writeExisting.selector;
        // TODO batchWrite
        // Transfer
        selectors[2] = OptionsHandler.transferLongs.selector;
        selectors[3] = OptionsHandler.transferShorts.selector;
        // Net
        selectors[4] = OptionsHandler.netOffsetting.selector;
        // Exercise
        selectors[5] = OptionsHandler.exerciseOptions.selector;
        // Redeem
        // selectors[6] = OptionsHandler.redeemCollateral.selector; // TODO
        // Skim
        // TODO skim

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    ///////// Core Protocol Invariant

    function invariant_A1_clearinghouseBalanceForAssetGteClearingLiability() public {
        handler.forEachAsset(this.assertA1);
    }

    function assertA1(IERC20 asset) public {
        assertGe(
            asset.balanceOf(address(clarity)),
            handler.ghost_clearingLiabilityFor(address(asset)),
            "clearinghouseBalanceForAssetGteClearingLiability"
        );
    }

    ///////// User Balance Invariants

    function invariant_B1_totalSupplyForTokenIdEqSumOfAllBalances() public {
        handler.forEachOption(this.assertB1);
    }

    function assertB1(uint256 optionTokenId) external {
        uint256 shortTokenId = optionTokenId.longToShort();
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

        IOption.Option memory option = clarity.option(optionTokenId);
        if (block.timestamp <= option.expiry) {
            assertEq(
                clarity.totalSupply(optionTokenId),
                handler.ghost_longSumFor(optionTokenId),
                "totalSupplyForTokenIdEqSumOfAllBalances long, before expiry"
            );
        } else {
            assertEq(
                clarity.totalSupply(optionTokenId),
                0,
                "totalSupplyForTokenIdEqSumOfAllBalances long, after expiry"
            );
        }
        assertApproxEqAbs(
            clarity.totalSupply(shortTokenId),
            handler.ghost_shortSumFor(optionTokenId),
            1,
            "totalSupplyForTokenIdEqSumOfAllBalances short"
        );
        assertEq(
            clarity.totalSupply(assignedShortTokenId),
            handler.ghost_assignedShortSumFor(optionTokenId),
            "totalSupplyForTokenIdEqSumOfAllBalances assignedShort"
        );
    }

    ///////// Options Supply and State Invariants

    function invariant_C1_totalSupplyOfLongsEqTotalSupplyOfShorts() public {
        handler.forEachOption(this.assertC1);
    }

    function assertC1(uint256 optionTokenId) external {
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

    function invariant_C2_totalSupplyOfShortsEqWSubNSubXSubRMulProportionUnassigned()
        public
    {
        handler.forEachOption(this.assertC2);
    }

    function assertC2(uint256 optionTokenId) external {
        uint256 shortTokenId = optionTokenId.longToShort();
        (uint256 w, uint256 n, uint256 x, uint256 r) = handler.optionState(optionTokenId);

        uint256 wSubN = w - n;
        uint256 rMulProportionUnassigned = (wSubN == 0) ? 0 : (r * (wSubN - x)) / wSubN;

        assertEq(
            clarity.totalSupply(shortTokenId),
            wSubN - x - rMulProportionUnassigned,
            "totalSupplyOfShortsEqWSubNSubXSubRMulProportionUnassigned"
        );
    }

    function invariant_C3_totalSupplyOfAssignedShortsEqXSubRMulProportionAssigned()
        public
    {
        handler.forEachOption(this.assertC3);
    }

    function assertC3(uint256 optionTokenId) external {
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();
        (uint256 w, uint256 n, uint256 x, uint256 r) = handler.optionState(optionTokenId);

        uint256 wSubN = w - n;
        uint256 rMulProportionAssigned = (wSubN == 0) ? 0 : (r * x) / wSubN;

        assertEq(
            clarity.totalSupply(assignedShortTokenId),
            x - rMulProportionAssigned,
            "totalSupplyOfAssignedShortsEqXSubRMulProportionAssigned"
        );
    }

    // TODO investigate counterexample
    // ├─ emit log_named_string(key: "Error", val: "amountWrittenGteNAddXAddR")
    // ├─ emit log(val: "Error: a >= b not satisfied [uint]")
    // ├─ emit log_named_uint(key: "  Value a", val: 15477 [1.547e4])
    // ├─ emit log_named_uint(key: "  Value b", val: 16689 [1.668e4])

    function invariant_C4_amountWrittenGteNAddXAddR() public {
        handler.forEachOption(this.assertC4);
    }

    function assertC4(uint256 optionTokenId) external {
        (uint256 w, uint256 n, uint256 x, uint256 r) = handler.optionState(optionTokenId);
        assertGe(w, n + x + r, "amountWrittenGteNAddXAddR");
    }

    function invariant_C5_amountNettedLteW() public {
        handler.forEachOption(this.assertC5);
    }

    function assertC5(uint256 optionTokenId) external {
        (uint256 w, uint256 n,,) = handler.optionState(optionTokenId);
        assertLe(n, w, "amountNettedLteW");
    }

    function invariant_C6_amountExercisedLteWSubN() public {
        handler.forEachOption(this.assertC6);
    }

    function assertC6(uint256 optionTokenId) external {
        (uint256 w, uint256 n, uint256 x,) = handler.optionState(optionTokenId);
        assertLe(x, w - n, "amountExercisedLteWSubN");
    }

    function invariant_C7_amountRedeemedLteWSubN() public {
        handler.forEachOption(this.assertC7);
    }

    function assertC7(uint256 optionTokenId) external {
        (uint256 w, uint256 n,, uint256 r) = handler.optionState(optionTokenId);
        assertLe(r, w - n, "amountRedeemedLteWSubN");
    }

    function invariant_C8_amountWrittenSubNSubREqTotalSupplyOfShortsSubAssignedShorts()
        public
    {
        handler.forEachOption(this.assertC8);
    }

    function assertC8(uint256 optionTokenId) external {
        uint256 shortTokenId = optionTokenId.longToShort();
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();
        (uint256 w, uint256 n,, uint256 r) = handler.optionState(optionTokenId);

        assertApproxEqAbs(
            w - n - r,
            clarity.totalSupply(shortTokenId) + clarity.totalSupply(assignedShortTokenId),
            1,
            "amountWrittenSubNSubREqTotalSupplyOfShortsSubAssignedShorts"
        );
    }

    ///////// Logging

    // function invariant_util_callSummary_andOptionState() public view {
    //     handler.callSummary();

    //     for (uint256 i = 0; i < handler.optionsCount(); i++) {
    //         uint256 optionTokenId = handler.optionTokenIdAt(i);

    //         (uint256 w, uint256 n, uint256 x, uint256 r) =
    // handler.optionState(optionTokenId);

    //         console2.log("Option Token ID ------------------", optionTokenId);
    //         console2.log("Amount written", w);
    //         console2.log("Amount netted", n);
    //         console2.log("Amount exercised", x);
    //         console2.log("Amount redeemed", r);
    //     }
    // }
}
