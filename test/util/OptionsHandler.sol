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

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract OptionsHandler is CommonBase, StdCheats, StdUtils {
    /////////

    using Assets for AssetSet;
    using Actors for ActorSet;
    using Options for OptionSet;

    using LibPosition for uint256;

    // Contract Under Test
    ClarityMarkets private clarity;

    // Collection Helpers
    AssetSet private baseAssets;
    AssetSet private quoteAssets;

    ActorSet private _actors;
    address private currentActor;

    OptionSet private _options;

    // Ghost Variables
    mapping(address => uint256) public ghost_clearingLiabilityFor;

    mapping(uint256 => uint256) public ghost_longSumFor;
    mapping(uint256 => uint256) public ghost_shortSumFor;
    mapping(uint256 => uint256) public ghost_assignedShortSumFor;

    // Assets
    // volatile
    IERC20 private WETHLIKE;
    IERC20 private WBTCLIKE;
    IERC20 private LINKLIKE;
    IERC20 private PEPELIKE;
    // stable
    IERC20 private LUSDLIKE;
    IERC20 private FRAXLIKE;
    IERC20 private USDCLIKE;
    IERC20 private USDTLIKE;

    uint8 private constant CONTRACT_SCALAR = 6;

    // Modifiers

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);

        _;
    }

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
        USDTLIKE = IERC20(address(new MockERC20("USDT Like", "USDTLIKE", 18)));
        vm.label(address(WETHLIKE), "WETHLIKE");
        vm.label(address(WBTCLIKE), "WBTCLIKE");
        vm.label(address(LINKLIKE), "LINKLIKE");
        vm.label(address(PEPELIKE), "PEPELIKE");
        vm.label(address(LUSDLIKE), "LUSDLIKE");
        vm.label(address(FRAXLIKE), "FRAXLIKE");
        vm.label(address(USDCLIKE), "USDCLIKE");
        vm.label(address(USDTLIKE), "USDTLIKE"); // TODO add Tether idiosyncrasies

        // setup test assets
        baseAssets.add(WETHLIKE);
        baseAssets.add(WBTCLIKE);
        baseAssets.add(LINKLIKE);
        baseAssets.add(PEPELIKE);
        quoteAssets.add(LUSDLIKE);
        quoteAssets.add(FRAXLIKE);
        quoteAssets.add(USDCLIKE);
        quoteAssets.add(USDTLIKE);

        // TODO consider dealing balances here
        // for (uint256 i = 0; i < baseAssets.count(); i++) {
        //     deal(
        //         address(baseAssets.at(i)),
        //         actor,
        //         scaleUpAssetAmount(baseAssets.at(i), STARTING_BALANCE)
        //     );
        // }
        // for (uint256 i = 0; i < quoteAssets.count(); i++) {
        //     deal(
        //         address(quoteAssets.at(i)),
        //         actor,
        //         scaleUpAssetAmount(quoteAssets.at(i), STARTING_BALANCE)
        //     );
        // }
    }

    // TODO refactor to rationalize test utilities and inheritance
    function scaleUpAssetAmount(IERC20 token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount * (10 ** token.decimals());
    }

    function scaleUpFullWriteAmountCall(IERC20 token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount * (10 ** (token.decimals() - CONTRACT_SCALAR));
    }

    function scaleUpFullWriteAmountPut(uint256 amount) internal pure returns (uint256) {
        return amount / (10 ** CONTRACT_SCALAR);
    }

    ///////// Actions

    // Write
    
    function writeNewCall(
        uint256 baseAssetIndex,
        uint256 quoteAssetIndex,
        uint32 expiry,
        uint256 strike,
        bool allowEarlyExercise,
        uint64 optionAmount
    ) external createActor {
        // set assets
        baseAssetIndex = baseAssetIndex % baseAssets.count();
        quoteAssetIndex = quoteAssetIndex % quoteAssets.count();

        // bind strike price
        strike =
            bound(strike, clarity.MINIMUM_STRIKE(), clarity.MAXIMUM_STRIKE());

        // deal asset, approve clearinghouse, write option
        vm.startPrank(currentActor);
        IERC20 baseAsset = baseAssets.at(baseAssetIndex);

        uint256 fullAmountForWrite = scaleUpFullWriteAmountCall(baseAsset, optionAmount);
        deal(address(baseAsset), currentActor, fullAmountForWrite);

        baseAsset.approve(address(clarity), type(uint256).max);

        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(baseAsset),
            quoteAsset: address(quoteAssets.at(quoteAssetIndex)),
            expiry: expiry,
            strike: strike,
            allowEarlyExercise: allowEarlyExercise,
            optionAmount: optionAmount
        });
        vm.stopPrank();

        // track object sets
        _options.add(optionTokenId);

        // track ghost variables
        ghost_clearingLiabilityFor[address(baseAsset)] += fullAmountForWrite;

        ghost_longSumFor[optionTokenId] += optionAmount;
        ghost_shortSumFor[optionTokenId] += optionAmount;
    }

    function writeNewPut(
        uint256 baseAssetIndex,
        uint256 quoteAssetIndex,
        uint32 expiry,
        uint256 strike,
        bool allowEarlyExercise,
        uint64 optionAmount
    ) external createActor {
        // set assets
        baseAssetIndex = baseAssetIndex % baseAssets.count();
        quoteAssetIndex = quoteAssetIndex % quoteAssets.count();

        // bind strike price and round to nearest million
        strike =
            bound(strike, clarity.MINIMUM_STRIKE(), clarity.MAXIMUM_STRIKE());
        strike = strike - (strike % (10 ** CONTRACT_SCALAR));

        // deal asset, approve clearinghouse, write option
        vm.startPrank(currentActor);
        IERC20 quoteAsset = quoteAssets.at(quoteAssetIndex);

        uint256 fullAmountForWrite = scaleUpFullWriteAmountPut(strike * optionAmount);
        deal(address(quoteAsset), currentActor, fullAmountForWrite);

        quoteAsset.approve(address(clarity), type(uint256).max);

        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(baseAssets.at(baseAssetIndex)),
            quoteAsset: address(quoteAsset),
            expiry: expiry,
            strike: strike,
            allowEarlyExercise: allowEarlyExercise,
            optionAmount: optionAmount
        });
        vm.stopPrank();

        // track object sets
        _options.add(optionTokenId);

        // track ghost variables
        ghost_clearingLiabilityFor[address(quoteAsset)] += fullAmountForWrite;

        ghost_longSumFor[optionTokenId] += optionAmount;
        ghost_shortSumFor[optionTokenId] += optionAmount;
    }

    function writeExistingCall() external {}

    function writeExistingPut() external {}

    function batchWriteCalls() external {}

    function batchWritePuts() external {}

    // Transfer

    function transferLongs() external {}

    function transferShorts() external {}

    // TODO add senders and operators, using transferFrom()

    // Net Off

    function netOff() external {}

    // Exercise

    function exerciseLong() external {}

    // Redeem

    function redeemShort() external {}

    ///////// Actors

    // TODO WIP

    // function actorsCount() external view returns (uint256) {
    //     return _actors.actors.length;
    // }

    // function actors() external view returns (address[] memory) {
    //     return _actors.actors;
    // }

    // function forEachActor(function(address) external func) public {
    //     _actors.forEach(func);
    // }

    // function reduceActors(
    //     uint256 acc,
    //     function(uint256,address) external returns (uint256) func
    // ) public returns (uint256) {
    //     return _actors.reduce(acc, func);
    // }

    // ///////// Assets

    // TODO WIP

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

    // function forEachAsset(function(IERC20) external func) public {
    //     _assets.forEach(func);
    // }

    // function reduceAssets(
    //     uint256 acc,
    //     function(uint256,IERC20) external returns (uint256) func
    // ) public returns (uint256) {
    //     return _assets.reduce(acc, func);
    // }

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
