// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {ActorSet, Actors} from "./Actors.sol";
import {AssetSet, Assets} from "./Assets.sol";
import {OptionSet, Options} from "./Options.sol";

// External Test Helpers
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2} from "forge-std/console2.sol";

// Test Contracts
import {MockERC20} from "./MockERC20.sol";

// Interfaces
import {IOption} from "../../src/interface/option/IOption.sol";

// Contracts
import "../../src/ClarityMarkets.sol";

contract OptionsHandler is CommonBase, StdCheats, StdUtils {
    /////////

    using Assets for AssetSet;
    using Actors for ActorSet;
    using Options for OptionSet;

    using LibMath for uint8;
    using LibMath for uint256;

    using LibPosition for uint256;

    ClarityMarkets private clarity;

    ///////// Ghost Variables

    // Clearinghouse Internal State
    mapping(uint256 => bytes32) private ghost_optionStateSlotFor;

    // Logging
    mapping(bytes32 => uint256) private calls;

    // Owners
    mapping(uint256 => address[]) public ghost_longOwnersOf;
    mapping(uint256 => address[]) public ghost_shortOwnersOf;

    // Clearing Liabilities // TODO replace with actual
    mapping(address => uint256) public ghost_clearingLiabilityFor;

    // Token Types // TODO replace with actual
    mapping(uint256 => uint256) public ghost_longSumFor;
    mapping(uint256 => uint256) public ghost_shortSumFor;
    mapping(uint256 => uint256) public ghost_assignedShortSumFor;

    ///////// Actors

    ActorSet private _actors;

    address private currentActor;

    ///////// Assets

    AssetSet private baseAssets;
    AssetSet private quoteAssets;

    // Volatile / Base Assets
    IERC20 private WETHLIKE;
    IERC20 private WBTCLIKE;
    IERC20 private LINKLIKE;
    IERC20 private PEPELIKE;

    // Stable / Quote Assets
    IERC20 private LUSDLIKE;
    IERC20 private FRAXLIKE;
    IERC20 private USDCLIKE;
    IERC20 private USDTLIKE;

    ///////// Options

    OptionSet private _options;

    ///////// Time

    uint32 private currentTime;

    ///////// Modifiers

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);

        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;

        _;
    }

    ///////// Construction

    constructor(ClarityMarkets _clarity) {
        clarity = _clarity;

        // deploy test assets
        WETHLIKE = IERC20(address(new MockERC20("WETH Like", "WETHLIKE", 18)));
        WBTCLIKE = IERC20(address(new MockERC20("WBTC Like", "WBTCLIKE", 8)));
        LINKLIKE = IERC20(address(new MockERC20("LINK Like", "LINKLIKE", 18)));
        PEPELIKE = IERC20(address(new MockERC20("PEPE Like", "PEPELIKE", 18)));
        LUSDLIKE = IERC20(address(new MockERC20("LUSD Like", "LUSDLIKE", 18)));
        FRAXLIKE = IERC20(address(new MockERC20("FRAX Like", "FRAXLIKE", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDC Like", "USDCLIKE", 6)));
        USDTLIKE = IERC20(address(new MockERC20("DAI Like", "DAILIKE", 18)));
        vm.label(address(WETHLIKE), "WETHLIKE");
        vm.label(address(WBTCLIKE), "WBTCLIKE");
        vm.label(address(LINKLIKE), "LINKLIKE");
        vm.label(address(PEPELIKE), "PEPELIKE");
        vm.label(address(LUSDLIKE), "LUSDLIKE");
        vm.label(address(FRAXLIKE), "FRAXLIKE");
        vm.label(address(USDCLIKE), "USDCLIKE");
        vm.label(address(USDTLIKE), "DAILIKE");

        // setup test assets
        baseAssets.add(WETHLIKE);
        baseAssets.add(WBTCLIKE);
        baseAssets.add(LINKLIKE);
        baseAssets.add(PEPELIKE);
        quoteAssets.add(LUSDLIKE);
        quoteAssets.add(FRAXLIKE);
        quoteAssets.add(USDCLIKE);
        quoteAssets.add(USDTLIKE);
    }

    // TODO refactor

    function getInternalOptionState(bytes32 slot)
        public
        view
        returns (uint64, uint64, uint64, uint64)
    {
        bytes32 state = vm.load(address(clarity), slot);

        return (
            uint64(uint256(state)),
            uint64(uint256(state >> 64)),
            uint64(uint256(state >> 128)),
            uint64(uint256(state >> 192))
        );
    }

    ///////// Actions

    // Write

    function writeNew(
        uint256 baseAssetIndex,
        uint256 quoteAssetIndex,
        uint256 expiry,
        uint256 strike,
        bool allowEarlyExercise,
        uint64 optionAmount,
        bool isCall
    ) external createActor countCall("writeNew") {
        // set assets
        baseAssetIndex = baseAssetIndex % baseAssets.count();
        quoteAssetIndex = quoteAssetIndex % quoteAssets.count();

        // bind expiry
        expiry = bound(expiry, 1_697_788_800, type(uint32).max - 1 days);

        // bind strike price and round to nearest million
        strike = bound(strike, clarity.MINIMUM_STRIKE(), clarity.MAXIMUM_STRIKE());
        strike = strike - (strike % (10 ** clarity.CONTRACT_SCALAR()));

        // deal asset, approve clearinghouse, and write options
        vm.startPrank(currentActor);
        IERC20 baseAsset = baseAssets.at(baseAssetIndex);
        IERC20 quoteAsset = quoteAssets.at(quoteAssetIndex);

        uint256 writeAssetAmount = isCall
            ? uint256(baseAsset.decimals().oneClearingUnit()) * uint256(optionAmount)
            : uint256(strike.actualScaledDownToClearingStrikeUnit()) * uint256(optionAmount);

        deal(address(baseAsset), currentActor, writeAssetAmount);

        baseAsset.approve(address(clarity), writeAssetAmount);

        // begin recording storage accesses
        vm.record();

        uint256 optionTokenId = isCall
            ? clarity.writeNewCall({
                baseAsset: address(baseAsset),
                quoteAsset: address(quoteAssets.at(quoteAssetIndex)),
                expiry: uint32(expiry),
                strike: strike,
                allowEarlyExercise: allowEarlyExercise,
                optionAmount: optionAmount
            })
            : clarity.writeNewPut({
                baseAsset: address(baseAssets.at(baseAssetIndex)),
                quoteAsset: address(quoteAsset),
                expiry: uint32(expiry),
                strike: strike,
                allowEarlyExercise: allowEarlyExercise,
                optionAmount: optionAmount
            });

        vm.stopPrank();

        // track object sets
        _options.add(optionTokenId);

        // save OptionState and XYZ storage slots
        (, bytes32[] memory writes) = vm.accesses(address(clarity));
        ghost_optionStateSlotFor[optionTokenId] = writes[5];

        // track ghost variables
        if (optionAmount > 0) {
            ghost_clearingLiabilityFor[address(baseAsset)] += writeAssetAmount;

            ghost_longSumFor[optionTokenId] += optionAmount;
            ghost_shortSumFor[optionTokenId] += optionAmount;

            ghost_longOwnersOf[optionTokenId].push(currentActor);
            ghost_shortOwnersOf[optionTokenId].push(currentActor);
        }
    }

    function writeExisting(uint256 optionIndex, uint256 optionAmount)
        external
        createActor
        countCall("writeExisting")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());

        // bind option amount
        optionAmount = bound(
            optionAmount,
            1,
            clarity.MAXIMUM_WRITABLE() - clarity.totalSupply(optionTokenId)
        );

        // get option info
        IOption.Option memory option = clarity.option(optionTokenId);

        // check for open interest
        _requireOpenInterest(optionTokenId);

        // set call vs. put specifics
        IERC20 writeAsset;
        uint256 writeAssetAmount;

        if (option.optionType == IOption.OptionType.CALL) {
            writeAsset = IERC20(option.baseAsset);
            writeAssetAmount =
                uint256(writeAsset.decimals().oneClearingUnit()) * uint256(optionAmount);
        } else {
            writeAsset = IERC20(option.quoteAsset);
            writeAssetAmount = uint256(
                option.strike.actualScaledDownToClearingStrikeUnit()
            ) * uint256(optionAmount);
        }

        // deal asset, approve clearinghouse, and write options
        vm.startPrank(currentActor);
        deal(address(writeAsset), currentActor, writeAssetAmount);
        writeAsset.approve(address(clarity), writeAssetAmount);
        clarity.writeExisting(optionTokenId, uint64(optionAmount));
        vm.stopPrank();

        // track ghost variables
        if (optionAmount > 0) {
            ghost_clearingLiabilityFor[address(writeAsset)] += writeAssetAmount;

            ghost_longSumFor[optionTokenId] += optionAmount;
            ghost_shortSumFor[optionTokenId] += optionAmount;

            ghost_longOwnersOf[optionTokenId].push(currentActor);
            ghost_shortOwnersOf[optionTokenId].push(currentActor);
        }
    }

    function batchWrite() external {
        // TODO
    }

    // Transfer

    function transferLongs(uint256 optionIndex, uint256 ownerIndex, uint256 optionAmount)
        external
        createActor
        countCall("transferLongs")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());

        _requireLongOwnersOf(optionTokenId);

        // set sender
        ownerIndex = ownerIndex % ghost_longOwnersOf[optionTokenId].length;
        address sender = ghost_longOwnersOf[optionTokenId][ownerIndex];

        // bind option amount
        optionAmount = bound(optionAmount, 1, clarity.balanceOf(sender, optionTokenId));

        // check for open interest
        _requireOpenInterest(optionTokenId);

        // transfer options to current actor
        vm.startPrank(sender);
        clarity.transfer(currentActor, optionTokenId, optionAmount);
        vm.stopPrank();

        // track ghost variables
        if (clarity.balanceOf(sender, optionTokenId) == 0) {
            ghost_longOwnersOf[optionTokenId][ownerIndex] = currentActor;
        } else {
            ghost_longOwnersOf[optionTokenId].push(currentActor);
        }
    }

    function transferShorts(uint256 optionIndex, uint256 ownerIndex, uint256 optionAmount)
        external
        createActor
        countCall("transferShorts")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());
        uint256 shortTokenId = optionTokenId.longToShort();

        // don't attempt to transfer already-assigned shorts
        vm.assume(clarity.totalSupply(optionTokenId.longToAssignedShort()) == 0);

        _requireShortOwnersOf(optionTokenId);

        // set sender
        ownerIndex = ownerIndex % ghost_shortOwnersOf[optionTokenId].length;
        address sender = ghost_shortOwnersOf[optionTokenId][ownerIndex];

        // bind option amount
        optionAmount = bound(optionAmount, 1, clarity.balanceOf(sender, shortTokenId));

        // check for open interest
        _requireOpenInterest(optionTokenId);

        // transfer options to current actor
        vm.startPrank(sender);
        clarity.transfer(currentActor, shortTokenId, optionAmount);
        vm.stopPrank();

        // track ghost variables
        if (clarity.balanceOf(sender, shortTokenId) == 0) {
            ghost_shortOwnersOf[optionTokenId][ownerIndex] = currentActor;
        } else {
            ghost_shortOwnersOf[optionTokenId].push(currentActor);
        }
    }

    // TODO add allowances and operators, using transferFrom()

    // Net

    function netOffsetting(uint256 optionIndex, uint256 ownerIndex, uint256 optionAmount)
        external
        countCall("netOffsetting")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());
        uint256 shortTokenId = optionTokenId.longToShort();

        _requireShortOwnersOf(optionTokenId);

        // set writer
        ownerIndex = ownerIndex % ghost_shortOwnersOf[optionTokenId].length;
        address writer = ghost_shortOwnersOf[optionTokenId][ownerIndex];

        uint256 longBalance = clarity.balanceOf(writer, optionTokenId);
        uint256 shortBalance = clarity.balanceOf(writer, shortTokenId);

        vm.assume(longBalance > 0);

        // bind option amount
        optionAmount = bound(optionAmount, 1, min(longBalance, shortBalance));

        // set call vs. put specifics
        IOption.Option memory option = clarity.option(optionTokenId);
        address writeAssetAddress = (option.optionType == IOption.OptionType.CALL)
            ? clarity.option(optionTokenId).baseAsset
            : clarity.option(optionTokenId).quoteAsset;

        // check for open interest
        _requireOpenInterest(optionTokenId);

        // net off position
        vm.startPrank(writer);
        uint256 writeAssetReturned =
            clarity.netOffsetting(optionTokenId, uint64(optionAmount));
        vm.stopPrank();

        // track ghost variables
        ghost_clearingLiabilityFor[writeAssetAddress] -= writeAssetReturned;

        ghost_longSumFor[optionTokenId] -= optionAmount;
        ghost_shortSumFor[optionTokenId] -= optionAmount;

        // if writer has no more shorts, swap and pop from short owners array
        if (clarity.balanceOf(writer, shortTokenId) == 0) {
            uint256 lastIndex = ghost_shortOwnersOf[optionTokenId].length - 1;
            address lastElement = ghost_shortOwnersOf[optionTokenId][lastIndex];
            ghost_shortOwnersOf[optionTokenId][ownerIndex] = lastElement;
            ghost_shortOwnersOf[optionTokenId].pop();
        }
        // if writer has no more longs, find, then swap and pop from long owners array
        if (clarity.balanceOf(writer, optionTokenId) == 0) {
            for (uint256 i = 0; i < ghost_longOwnersOf[optionTokenId].length; i++) {
                if (ghost_longOwnersOf[optionTokenId][i] == writer) {
                    uint256 lastIndex = ghost_longOwnersOf[optionTokenId].length - 1;
                    address lastElement = ghost_longOwnersOf[optionTokenId][lastIndex];
                    ghost_longOwnersOf[optionTokenId][i] = lastElement;
                    ghost_longOwnersOf[optionTokenId].pop();
                    break;
                }
            }
        }
    }

    // Exercise

    function exerciseOption(uint256 optionIndex, uint256 ownerIndex, uint256 optionAmount)
        external
        countCall("exerciseOption")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());

        _requireLongOwnersOf(optionTokenId);

        // set holder
        ownerIndex = ownerIndex % ghost_longOwnersOf[optionTokenId].length;
        address holder = ghost_longOwnersOf[optionTokenId][ownerIndex];

        // bind option amount
        optionAmount = bound(optionAmount, 1, clarity.balanceOf(holder, optionTokenId));

        // get option info
        IOption.Option memory option = clarity.option(optionTokenId);

        // check for open interest
        _requireOpenInterest(optionTokenId);

        // warp into exercise window, if necessary
        if (
            block.timestamp > option.expiry
                || (
                    option.exerciseStyle == IOption.ExerciseStyle.EUROPEAN
                        && block.timestamp < option.expiry - 1 days
                )
        ) {
            vm.warp(option.expiry); // TODO improve time injection
        }

        // set call vs. put specifics
        IERC20 writeAsset;
        IERC20 exerciseAsset;
        uint256 writeAssetAmount;
        uint256 exerciseAssetAmount;

        if (option.optionType == IOption.OptionType.CALL) {
            writeAsset = IERC20(option.baseAsset);
            exerciseAsset = IERC20(option.quoteAsset);
            writeAssetAmount =
                uint256(writeAsset.decimals().oneClearingUnit()) * uint256(optionAmount);
            exerciseAssetAmount = uint256(
                option.strike.actualScaledDownToClearingStrikeUnit()
            ) * uint256(optionAmount);
        } else {
            writeAsset = IERC20(option.quoteAsset);
            exerciseAsset = IERC20(option.baseAsset);
            writeAssetAmount = uint256(
                option.strike.actualScaledDownToClearingStrikeUnit()
            ) * uint256(optionAmount);
            exerciseAssetAmount = uint256(exerciseAsset.decimals().oneClearingUnit())
                * uint256(optionAmount);
        }

        // deal asset, approve clearinghouse, and exercise options
        deal(address(exerciseAsset), holder, exerciseAssetAmount);
        vm.startPrank(holder);
        exerciseAsset.approve(address(clarity), exerciseAssetAmount);
        clarity.exerciseOption(optionTokenId, uint64(optionAmount));
        vm.stopPrank();

        // track ghost variables
        ghost_clearingLiabilityFor[address(writeAsset)] -= writeAssetAmount;
        ghost_clearingLiabilityFor[address(exerciseAsset)] += exerciseAssetAmount;

        ghost_longSumFor[optionTokenId] -= optionAmount;
        ghost_shortSumFor[optionTokenId] -= optionAmount;
        ghost_assignedShortSumFor[optionTokenId] += optionAmount;

        // if holder has no more options, swap and pop from long owners array
        if (clarity.balanceOf(holder, optionTokenId) == 0) {
            uint256 lastIndex = ghost_longOwnersOf[optionTokenId].length - 1;
            address lastElement = ghost_longOwnersOf[optionTokenId][lastIndex];
            ghost_longOwnersOf[optionTokenId][ownerIndex] = lastElement;
            ghost_longOwnersOf[optionTokenId].pop();
        }
        // if a given writer has no more shorts, swap and pop from short owners array
        for (uint256 i = 0; i < ghost_shortOwnersOf[optionTokenId].length; i++) {
            uint256 shortBalance = clarity.balanceOf(
                ghost_shortOwnersOf[optionTokenId][i], optionTokenId.longToShort()
            );
            if (shortBalance == 0) {
                uint256 lastIndex = ghost_shortOwnersOf[optionTokenId].length - 1;
                address lastElement = ghost_shortOwnersOf[optionTokenId][lastIndex];
                ghost_shortOwnersOf[optionTokenId][i] = lastElement;
                ghost_shortOwnersOf[optionTokenId].pop();
            }
        }
    }

    // Redeem

    function redeemCollateral(uint256 optionIndex, uint256 ownerIndex)
        external
        countCall("redeemCollateral")
    {
        _requireOptions();

        // set option token id
        uint256 optionTokenId = _options.at(optionIndex % _options.count());
        uint256 shortTokenId = optionTokenId.longToShort();

        _requireShortOwnersOf(optionTokenId);

        // set writer
        ownerIndex = ownerIndex % ghost_shortOwnersOf[optionTokenId].length;
        address writer = ghost_shortOwnersOf[optionTokenId][ownerIndex];

        // track balances, before redeem
        uint256 shortBalance = clarity.balanceOf(writer, shortTokenId);
        uint256 assignedBalance =
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort());

        // get option info
        IOption.Option memory option = clarity.option(optionTokenId);

        // warp after expiry, if necessary
        if (block.timestamp <= option.expiry) {
            vm.warp(option.expiry + 1 seconds); // TODO improve time injection
        }

        // set call vs. put specifics
        IERC20 writeAsset;
        IERC20 exerciseAsset;
        if (option.optionType == IOption.OptionType.CALL) {
            writeAsset = IERC20(option.baseAsset);
            exerciseAsset = IERC20(option.quoteAsset);
        } else {
            writeAsset = IERC20(option.quoteAsset);
            exerciseAsset = IERC20(option.baseAsset);
        }

        // redeem shorts
        vm.startPrank(writer);
        (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed) =
            clarity.redeemCollateral(shortTokenId);
        vm.stopPrank();

        // track ghost variables
        ghost_clearingLiabilityFor[address(writeAsset)] -= writeAssetRedeemed;
        ghost_clearingLiabilityFor[address(exerciseAsset)] -= exerciseAssetRedeemed;

        ghost_shortSumFor[optionTokenId] -= shortBalance;
        ghost_assignedShortSumFor[optionTokenId] -= assignedBalance;

        // if a writer has no more shorts, swap and pop from short owners array
        if (clarity.balanceOf(writer, shortTokenId) == 0) {
            uint256 lastIndex = ghost_shortOwnersOf[optionTokenId].length - 1;
            address lastElement = ghost_shortOwnersOf[optionTokenId][lastIndex];
            ghost_shortOwnersOf[optionTokenId][ownerIndex] = lastElement;
            ghost_shortOwnersOf[optionTokenId].pop();
        }
    }

    function sendExtra() external {
        // TODO
    }

    function skim() external {
        // TODO
    }

    // Util

    function callSummary() external view {
        console2.log("Call summary:");
        console2.log("-------------------");
        // Write
        console2.log("writeNew", calls["writeNew"]);
        console2.log("writeExisting", calls["writeExisting"]);
        console2.log("writeBatch", calls["writeBatch"]);
        // Transfer
        console2.log("transferLongs", calls["transferLongs"]);
        console2.log("transferShorts", calls["transferShorts"]);
        // Net
        console2.log("netOffsetting", calls["netOffsetting"]);
        // Exercise
        console2.log("exerciseOption", calls["exerciseOption"]);
        // Redeem
        console2.log("redeemCollateral", calls["redeemCollateral"]);
        // Skim
        console2.log("skim", calls["skim"]);
    }

    ///////// Checks

    function _requireOpenInterest(uint256 optionTokenId) private view {
        vm.assume(clarity.totalSupply(optionTokenId) > 0);
    }

    function _requireOptions() private view {
        vm.assume(_options.count() > 0);
    }

    function _requireLongOwnersOf(uint256 optionTokenId) private view {
        vm.assume(ghost_longOwnersOf[optionTokenId].length > 0);
    }

    function _requireShortOwnersOf(uint256 optionTokenId) private view {
        vm.assume(ghost_shortOwnersOf[optionTokenId].length > 0);
    }

    ///////// Helper Functions

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    ///////// Assets

    function baseAssetsCount() external view returns (uint256) {
        return baseAssets.assets.length;
    }

    function baseAssetAt(uint256 index) external view returns (IERC20) {
        return baseAssets.at(index);
    }

    function quoteAssetsCount() external view returns (uint256) {
        return quoteAssets.assets.length;
    }

    function quoteAssetAt(uint256 index) external view returns (IERC20) {
        return quoteAssets.at(index);
    }

    ///////// Options

    // TODO WIP

    function optionsCount() external view returns (uint256) {
        return _options.count();
    }

    function optionTokenIdAt(uint256 index)
        external
        view
        returns (uint256 optionTokenId)
    {
        return _options.at(index);
    }

    function optionState(uint256 optionTokenId)
        external
        view
        returns (uint256 written, uint256 netted, uint256 exercised, uint256 redeemed)
    {
        return getInternalOptionState(ghost_optionStateSlotFor[optionTokenId]);
    }

    // function forEachOption(function(uint256) external func) public {
    //     _options.forEach(func);
    // }

    // function reduceOptions(
    //     uint256 acc,
    //     uint256 tokenId,
    //     function(uint256,address,uint256) external returns (uint256) func
    // ) public returns (uint256) {
    //     return _options.reduce(currentActor, tokenId, acc, func);
    // }
}
