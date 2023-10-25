// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "./util/MockERC20.sol";

import "../src/ClarityMarkets.sol";
import "../src/interface/option/IOptionToken.sol";
import "../src/interface/option/IOptionEvents.sol";

abstract contract BaseClarityMarketsTest is Test {
    /////////

    // DCP
    ClarityMarkets internal clarity;

    // Actors
    address internal writer;
    address internal writer1;
    address internal writer2;
    address internal writer3;
    address internal writer4;
    address internal writer5;
    address internal writer6;
    address internal writer7;
    address internal writer8;
    address internal writer9;
    address internal writer10;
    address internal holder;
    address internal holder1;
    address internal holder2;
    address internal holder3;
    address internal holder4;
    address internal holder5;
    address internal holder6;
    address internal holder7;
    address internal holder8;
    address internal holder9;
    address internal holder10;

    uint256 internal writer1WethBalance;
    uint256 internal writer1LusdBalance;
    uint256 internal writer2WethBalance;
    uint256 internal writer2LusdBalance;
    uint256 internal writer3WethBalance;
    uint256 internal writer3LusdBalance;
    uint256 internal holder1WethBalance;
    uint256 internal holder1LusdBalance;
    uint256 internal holder2WethBalance;
    uint256 internal holder2LusdBalance;

    uint256 internal constant NUM_TEST_USERS = 10;

    // Assets
    IERC20 internal WETHLIKE;
    IERC20 internal WBTCLIKE;
    IERC20 internal LINKLIKE;
    IERC20 internal PEPELIKE;
    IERC20 internal LUSDLIKE;
    IERC20 internal USDCLIKE;

    uint256 internal constant STARTING_BALANCE = 1_000_000;

    // Time
    uint32 internal constant DAWN = 1_697_788_800; // Fri Oct 20 2023 08:00:00 GMT+0000
    uint32 internal constant FRI1 = DAWN + 7 days;
    uint32 internal constant FRI2 = DAWN + 14 days;
    uint32 internal constant FRI3 = DAWN + 21 days;
    uint32 internal constant FRI4 = DAWN + 28 days;
    uint32 internal constant THU1 = DAWN + 6 days;
    uint32 internal constant THU2 = DAWN + 13 days;
    uint32 internal constant THU3 = DAWN + 20 days;
    uint32 internal constant THU4 = DAWN + 27 days;

    uint32[][] internal americanExDailies;
    uint32[][] internal americanExWeeklies;
    uint32[][] internal americanExMonthlies;
    uint32[][] internal americanExQuarterlies;
    uint32[][] internal europeanExDailies;
    uint32[][] internal europeanExWeeklies;
    uint32[][] internal europeanExMonthlies;
    uint32[][] internal europeanExQuarterlies;
    uint32[] internal bermudanExEOW; // next 4 weeks
    uint32[] internal bermudanExEOM; // next Oct, Nov, Dec, Jan
    uint32[] internal bermudanExEOQ; // next Mar, Jun, Sep, Dec
    uint32[] internal bermudanExEOY; // next 4 years

    uint256 internal constant NUM_TEST_EXERCISE_WINDOWS = 4;

    // Options
    uint256 internal oti1;
    uint256 internal oti2;
    uint256 internal oti3;
    uint256 internal oti4;
    uint256 internal oti5;

    function setUp() public {
        // dawn
        vm.warp(DAWN);

        // deploy DCP
        clarity = new ClarityMarkets();

        // deploy test assets
        WETHLIKE = IERC20(address(new MockERC20("WETHLike", "WETHLIKE", 18)));
        WBTCLIKE = IERC20(address(new MockERC20("WBTCLike", "WBTCLIKE", 8)));
        LINKLIKE = IERC20(address(new MockERC20("LINKLike", "LINKLIKE", 18)));
        PEPELIKE = IERC20(address(new MockERC20("PEPELike", "PEPELIKE", 18)));
        LUSDLIKE = IERC20(address(new MockERC20("LUSDLike", "LUSDLIKE", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDCLike", "USDCLIKE", 6)));

        // make test actors and mint assets
        address[] memory writers = new address[](NUM_TEST_USERS);
        address[] memory holders = new address[](NUM_TEST_USERS);
        for (uint256 i = 0; i < NUM_TEST_USERS; i++) {
            writers[i] = makeAddress(string(abi.encodePacked("writer", i + 1)));
            holders[i] = makeAddress(string(abi.encodePacked("holder", i + 1)));

            deal(address(WETHLIKE), writers[i], scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(WBTCLIKE), writers[i], scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
            deal(address(LINKLIKE), writers[i], scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(PEPELIKE), writers[i], scaleUpAssetAmount(PEPELIKE, STARTING_BALANCE));
            deal(address(LUSDLIKE), writers[i], scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
            deal(address(USDCLIKE), writers[i], scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
            deal(address(WETHLIKE), holders[i], scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(WBTCLIKE), holders[i], scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
            deal(address(LINKLIKE), holders[i], scaleUpAssetAmount(LINKLIKE, STARTING_BALANCE));
            deal(address(PEPELIKE), holders[i], scaleUpAssetAmount(PEPELIKE, STARTING_BALANCE));
            deal(address(LUSDLIKE), holders[i], scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
            deal(address(USDCLIKE), holders[i], scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        }
        writer = writers[0];
        writer1 = writers[0];
        writer2 = writers[1];
        writer3 = writers[2];
        writer4 = writers[3];
        writer5 = writers[4];
        writer6 = writers[5];
        writer7 = writers[6];
        writer8 = writers[7];
        writer9 = writers[8];
        writer10 = writers[9];
        holder = holders[0];
        holder1 = holders[0];
        holder2 = holders[1];
        holder3 = holders[2];
        holder4 = holders[3];
        holder5 = holders[4];
        holder6 = holders[5];
        holder7 = holders[6];
        holder8 = holders[7];
        holder9 = holders[8];
        holder10 = holders[9];

        // make test exercise windows
        americanExWeeklies = new uint32[][](4);
        americanExWeeklies[0] = new uint32[](2);
        americanExWeeklies[1] = new uint32[](2);
        americanExWeeklies[2] = new uint32[](2);
        americanExWeeklies[3] = new uint32[](2);
        americanExWeeklies[0][0] = DAWN + 1 seconds;
        americanExWeeklies[0][1] = FRI1;
        americanExWeeklies[1][0] = FRI1 + 1 seconds;
        americanExWeeklies[1][1] = FRI2;
        americanExWeeklies[2][0] = FRI2 + 1 seconds;
        americanExWeeklies[2][1] = FRI3;
        americanExWeeklies[3][0] = FRI3 + 1 seconds;
        americanExWeeklies[3][1] = FRI4;
    }

    ///////// Actor Helpers

    function makeAddress(string memory name) internal returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);

        return addr;
    }

    ///////// Asset Helpers

    function scaleUpAssetAmount(IERC20 token, uint256 amount) internal view returns (uint256) {
        return amount * 10 ** token.decimals();
    }

    function scaleDownOptionAmount(uint256 amount) internal view returns (uint80) {
        return SafeCastLib.safeCastTo80(amount / 10 ** clarity.OPTION_CONTRACT_SCALAR());
    }

    ///////// Assertion Helpers

    function assertEq(IOptionToken.OptionType a, IOptionToken.OptionType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [OptionType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOptionToken.OptionType a, IOptionToken.OptionType b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOptionToken.ExerciseStyle a, IOptionToken.ExerciseStyle b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [ExerciseStyle]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOptionToken.ExerciseStyle a, IOptionToken.ExerciseStyle b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOptionToken.ExerciseWindow memory a, IOptionToken.ExerciseWindow memory b) internal {
        if (a.exerciseTimestamp != b.exerciseTimestamp) {
            emit log("Error: a == b not satisfied [ExerciseWindow.exerciseTimestamp]");
            emit log_named_uint("      Left", a.exerciseTimestamp);
            emit log_named_uint("     Right", b.exerciseTimestamp);
            fail();
        }
        if (a.expiryTimestamp != b.expiryTimestamp) {
            emit log("Error: a == b not satisfied [ExerciseWindow.expiryTimestamp]");
            emit log_named_uint("      Left", a.expiryTimestamp);
            emit log_named_uint("     Right", b.expiryTimestamp);
            fail();
        }
    }

    function assertEq(
        IOptionToken.ExerciseWindow memory a,
        IOptionToken.ExerciseWindow memory b,
        string memory err
    ) internal {
        if (a.exerciseTimestamp != b.exerciseTimestamp || a.expiryTimestamp != b.expiryTimestamp) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    // TODO dupe for now, until 0.8.22 resolves this bug

    event CreateOption(
        uint256 indexed optionTokenId,
        address indexed baseAsset,
        address indexed quoteAsset,
        uint32 exerciseTimestamp,
        uint32 expiryTimestamp,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    );

    event WriteOptions(address indexed caller, uint256 indexed optionTokenId, uint80 optionAmount);
}