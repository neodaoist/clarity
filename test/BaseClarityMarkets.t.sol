// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "./util/MockERC20.sol";

import "../src/ClarityMarkets.sol";

abstract contract BaseClarityMarketsTest is Test {
    /////////

    // DCP
    ClarityMarkets internal clarity;

    // Actors
    address internal writer;
    address internal holder;
    address[] internal writers;
    address[] internal holders;

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

    uint40[] internal americanExDailies;
    uint40[] internal americanExWeeklies;
    uint40[] internal americanExMonthlies;
    uint40[] internal americanExQuarterlies;
    uint40[] internal europeanExDailies;
    uint40[] internal europeanExWeeklies;
    uint40[] internal europeanExMonthlies;
    uint40[] internal europeanExQuarterlies;
    uint40[] internal bermudanExEOWs;
    uint40[] internal bermudanExEOMs;
    uint40[] internal bermudanExEOQs;
    uint40[] internal bermudanExEOYs;

    uint256 internal constant NUM_TEST_EXERCISE_WINDOWS = 4;

    function setUp() public {
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
        writers = new address[](NUM_TEST_USERS);
        holders = new address[](NUM_TEST_USERS);
        for (uint256 i = 0; i < NUM_TEST_USERS; i++) {
            writers[i] = makeAddress(string(abi.encodePacked("writer", i + 1)));
            holders[i] = makeAddress(string(abi.encodePacked("holder", i + 1)));

            deal(address(WETHLIKE), writers[i], scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(WBTCLIKE), writers[i], scaleAssetAmount(WBTCLIKE, STARTING_BALANCE));
            deal(address(LINKLIKE), writers[i], scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(PEPELIKE), writers[i], scaleAssetAmount(PEPELIKE, STARTING_BALANCE));
            deal(address(LUSDLIKE), writers[i], scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));
            deal(address(USDCLIKE), writers[i], scaleAssetAmount(USDCLIKE, STARTING_BALANCE));
            deal(address(WETHLIKE), holders[i], scaleAssetAmount(WETHLIKE, STARTING_BALANCE));
            deal(address(WBTCLIKE), holders[i], scaleAssetAmount(WBTCLIKE, STARTING_BALANCE));
            deal(address(LINKLIKE), holders[i], scaleAssetAmount(LINKLIKE, STARTING_BALANCE));
            deal(address(PEPELIKE), holders[i], scaleAssetAmount(PEPELIKE, STARTING_BALANCE));
            deal(address(LUSDLIKE), holders[i], scaleAssetAmount(LUSDLIKE, STARTING_BALANCE));
            deal(address(USDCLIKE), holders[i], scaleAssetAmount(USDCLIKE, STARTING_BALANCE));
        }
        writer = writers[0];
        holder = holders[0];

        // make test exercise windows
        americanExWeeklies = new uint40[](4);
        for (uint256 i = 1; i <= NUM_TEST_EXERCISE_WINDOWS; i++) {
            uint32 earliestExercise = uint32(DAWN + (1 seconds * i));
            uint32 expiry = uint32(DAWN + (7 days * i));

            americanExWeeklies[i - 1] = (earliestExercise << 32) + expiry;
        }
    }

    ///////// Actor Helpers

    function makeAddress(string memory name) internal returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);

        return addr;
    }

    ///////// Asset Helpers

    function scaleAssetAmount(IERC20 token, uint256 amount) internal view returns (uint256) {
        return amount * 10 ** token.decimals();
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
}
