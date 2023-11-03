// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {ActorSet, LibActorSet} from "./ActorSet.sol";
import {AssetSet, LibAssetSet} from "./AssetSet.sol";
import {OptionSet, LibOptionSet} from "./OptionSet.sol";

// External Test Helpers
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2} from "forge-std/console2.sol";

// Test Contracts
import {MockERC20} from "./MockERC20.sol";

// Contract Under Test
import "../../src/ClarityMarkets.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    /////////

    using LibToken for uint256;
    using LibAssetSet for AssetSet;
    using LibActorSet for ActorSet;
    using LibOptionSet for OptionSet;

    ClarityMarkets private clarity; // CUT

    // Collection Helpers
    AssetSet private _assets;
    ActorSet private _actors;
    OptionSet private _options;

    // Ghost Variables
    mapping(uint256 => uint256) public ghost_longSumFor;
    mapping(uint256 => uint256) public ghost_shortSumFor;
    mapping(uint256 => uint256) public ghost_assignedShortSumFor;

    // mapping(uint256 => uint256) public ghost_writeSum;
    // mapping(uint256 => uint256) public ghost_netSum;
    // mapping(uint256 => uint256) public ghost_exerciseSum;
    // mapping(uint256 => uint256) public ghost_redeemSum;

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

    IERC20[] private possibleAssets;

    uint256 internal constant STARTING_BALANCE = 1_000_000;

    // Actors
    address private actor;
    // TODO

    constructor(ClarityMarkets _clarity) {
        clarity = _clarity;

        // deploy test assets
        WETHLIKE = IERC20(address(new MockERC20("WETH Like", "WETHLIKE", 18)));
        WBTCLIKE = IERC20(address(new MockERC20("WBTC Like", "WBTCLIKE", 8)));
        LINKLIKE = IERC20(address(new MockERC20("LINK Like", "LINKLIKE", 18)));
        PEPELIKE = IERC20(address(new MockERC20("PEPE Like", "PEPELIKE", 18)));
        LUSDLIKE = IERC20(address(new MockERC20("LUSD Like", "LUSDLIKE", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDC Like", "USDCLIKE", 6)));

        // setup possible assets
        possibleAssets.push(WETHLIKE);
        possibleAssets.push(WBTCLIKE);
        possibleAssets.push(LINKLIKE);
        possibleAssets.push(PEPELIKE);
        possibleAssets.push(LUSDLIKE);
        possibleAssets.push(FRAXLIKE);
        possibleAssets.push(USDCLIKE);
        possibleAssets.push(USDTLIKE);

        // deal // TODO replace with multiple actors
        for (uint256 j = 0; j < possibleAssets.length; j++) {
            deal(
                address(possibleAssets[j]),
                actor,
                scaleUpAssetAmount(possibleAssets[j], STARTING_BALANCE)
            );
        }
    }

    // TODO refactor to rationalize test utilities and inheritance
    function scaleUpAssetAmount(IERC20 token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount * (10 ** token.decimals());
    }

    function clearingLiabilityFor(IERC20 asset)
        public
        returns (uint256 clearingLiability)
    {}

    ///////// Actions

    // Write

    function writeNewCall(
        uint256 baseAssetIndex,
        uint256 quoteAssetIndex,
        uint256 exerciseTimestamp,
        uint256 expiryTimestamp,
        uint256 strikePrice,
        uint256 optionAmount
    ) external {
        // bound assets
        baseAssetIndex = bound(baseAssetIndex, 0, possibleAssets.length);
        quoteAssetIndex = bound(quoteAssetIndex, 0, possibleAssets.length);
        require(baseAssetIndex != quoteAssetIndex, "base == quote"); // TODO improve

        // bound timestamps and setup ExerciseWindow
        exerciseTimestamp = bound(exerciseTimestamp, 1, type(uint32).max - 365 days);
        expiryTimestamp = bound(
            expiryTimestamp, exerciseTimestamp + 1 seconds, type(uint32).max - 1 seconds
        );
        uint32[] memory exerciseWindow = new uint32[](2);
        exerciseWindow[0] = uint32(exerciseTimestamp);
        exerciseWindow[1] = uint32(expiryTimestamp);

        // bound strike price and option amount
        strikePrice = bound(
            strikePrice, clarity.MINIMUM_STRIKE_PRICE(), clarity.MAXIMUM_STRIKE_PRICE()
        );
        optionAmount = bound(optionAmount, 10, type(uint32).max); // TODO improve

        // write call
        vm.prank(actor);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(possibleAssets[baseAssetIndex]),
            quoteAsset: address(possibleAssets[quoteAssetIndex]),
            exerciseWindow: exerciseWindow,
            strikePrice: strikePrice,
            optionAmount: uint32(optionAmount)
        });

        // track object sets
        _assets.add(possibleAssets[baseAssetIndex]);
        _assets.add(possibleAssets[quoteAssetIndex]);
        _options.add(optionTokenId);

        // track ghost variables
        // ghost_longSumFor[optionTokenId] += optionAmount;
        // ghost_shortSumFor[optionTokenId] += optionAmount;
        // // ghost_assignedShortSumFor[optionTokenId] += 0; // no change
    }

    function writeNewPut() external {}

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

    function exercise() external {}

    // Redeem

    function redeem() external {}

    ///////// Actors

    function actors() external view returns (address[] memory) {
        return _actors.actors;
    }

    function forEachActor(function(address) external func) public {
        _actors.forEach(func);
    }

    function reduceActors(
        uint256 acc,
        function(uint256,address) external returns (uint256) func
    ) public returns (uint256) {
        return _actors.reduce(acc, func);
    }

    ///////// Assets

    function assets() external view returns (IERC20[] memory) {
        return _assets.assets;
    }

    function forEachAsset(function(IERC20) external func) public {
        _assets.forEach(func);
    }

    function reduceAssets(
        uint256 acc,
        function(uint256,IERC20) external returns (uint256) func
    ) public returns (uint256) {
        return _assets.reduce(acc, func);
    }

    ///////// Options

    function options() external view returns (uint256[] memory) {
        return _options.options;
    }

    function forEachOption(function(uint256) external func) public {
        _options.forEach(func);
    }

    function reduceOptions(
        uint256 acc,
        function(uint256,uint256) external returns (uint256) func
    ) public returns (uint256) {
        return _options.reduce(acc, func);
    }
}
