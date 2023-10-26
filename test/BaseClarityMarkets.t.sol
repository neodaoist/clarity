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

    ///////// Test Backgrounds

    // Parameterized strike price to test various assignment paths, via different
    // assigment seeds and therefore different initial assignment indices:
    //   1707e18 -- assignment path 0, 1, 2
    //   1702e18 -- assignment path 0, 2, 1
    //   1712e18 -- assignment path 1, 0, 2
    //   1700e18 -- assignment path 1, 2, 0
    //   1706e18 -- assignment path 2, 0, 1
    //   1715e18 -- assignment path 2, 1, 0
    modifier withSimpleBackground(uint256 strikePrice) {
        writer1WethBalance = WETHLIKE.balanceOf(writer1);
        writer1LusdBalance = LUSDLIKE.balanceOf(writer1);
        writer2WethBalance = WETHLIKE.balanceOf(writer2);
        writer2LusdBalance = LUSDLIKE.balanceOf(writer2);
        holder1WethBalance = WETHLIKE.balanceOf(holder1);
        holder1LusdBalance = LUSDLIKE.balanceOf(holder1);

        // Given writer1 writes 0.15 options of oti1
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        oti1 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], strikePrice, 0.15e6
        );
        vm.stopPrank();

        // And writer2 writes 0.35 options of oti1
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(oti1, 0.35e6);
        vm.stopPrank();

        // And writer1 writes 2 options of oti1
        vm.prank(writer1);
        clarity.write(oti1, 2e6);

        // And writer1 transfers 2.15 longs of oti1 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti1, 2.15e6);

        // And writer2 transfers 0.35 longs of oti1 to holder1
        vm.prank(writer2);
        clarity.transfer(holder1, oti1, 0.35e6);

        // pre exercise check option balances
        // oti1
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 2.15e6, "oti1 writer1 short balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0, "oti1 writer1 assigned balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0.35e6, "oti1 writer2 short balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0, "oti1 writer2 assigned balance before exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2.5e6, "oti1 holder1 long balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance before exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.15),
            "writer1 WETH balance before exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer1), writer1LusdBalance, "writer1 LUSD balance before exercise");
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.35),
            "writer2 WETH balance before exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer2), writer2LusdBalance, "writer2 LUSD balance before exercise");
        assertEq(WETHLIKE.balanceOf(holder1), holder1WethBalance, "holder1 WETH balance before exercise");
        assertEq(LUSDLIKE.balanceOf(holder1), holder1LusdBalance, "holder1 LUSD balance before exercise");

        // warp to exercise window
        vm.warp(americanExWeeklies[0][1]);

        _;
    }

    modifier withMediumBackground() {
        //
        _;
    }

    modifier withComplexBackground() {
        writer1WethBalance = WETHLIKE.balanceOf(writer1);
        writer1LusdBalance = LUSDLIKE.balanceOf(writer1);
        writer2WethBalance = WETHLIKE.balanceOf(writer2);
        writer2LusdBalance = LUSDLIKE.balanceOf(writer2);
        writer3WethBalance = WETHLIKE.balanceOf(writer3);
        writer3LusdBalance = LUSDLIKE.balanceOf(writer3);
        holder1WethBalance = WETHLIKE.balanceOf(holder1);
        holder1LusdBalance = LUSDLIKE.balanceOf(holder1);
        holder2WethBalance = WETHLIKE.balanceOf(holder2);
        holder2LusdBalance = LUSDLIKE.balanceOf(holder2);

        // Given writer1 writes 1.25 options of oti1
        vm.startPrank(writer1);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        oti1 = clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1.25e6);
        vm.stopPrank();

        // And writer2 writes 0.25 options of oti1
        vm.startPrank(writer2);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.write(oti1, 0.25e6);
        vm.stopPrank();

        // And writer1 transfers 0.5 shorts of oti1 to writer3
        vm.prank(writer1);
        clarity.transfer(writer3, oti1 + 1, 0.5e6);

        // And writer1 writes 1 option of oti2
        vm.prank(writer1);
        oti2 = clarity.writeCall(address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 1e6);

        // And writer1 writes 1 option of oti1
        vm.prank(writer1);
        clarity.write(oti1, 1e6);

        // And writer1 transfers 2.25 longs of oti1 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti1, 2.25e6);

        // And writer2 transfers 0.2 longs of oti1 to holder1
        vm.prank(writer2);
        clarity.transfer(holder1, oti1, 0.2e6);

        // And writer2 transfers 0.05 longs of oti1 to holder2
        vm.prank(writer2);
        clarity.transfer(holder2, oti1, 0.05e6);

        // And writer1 transfers 0.95 longs of oti2 to holder1
        vm.prank(writer1);
        clarity.transfer(holder1, oti2, 0.95e6);

        // pre exercise check option balances
        // oti1
        assertEq(clarity.balanceOf(writer1, oti1), 0, "oti1 writer1 long balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 1), 1.75e6, "oti1 writer1 short balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti1 + 2), 0, "oti1 writer1 assigned balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1), 0, "oti1 writer2 long balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 1), 0.25e6, "oti1 writer2 short balance before exercise");
        assertEq(clarity.balanceOf(writer2, oti1 + 2), 0, "oti1 writer2 assigned balance before exercise");
        assertEq(clarity.balanceOf(writer3, oti1), 0, "oti1 writer3 long balance before exercise");
        assertEq(clarity.balanceOf(writer3, oti1 + 1), 0.5e6, "oti1 writer3 short balance before exercise");
        assertEq(clarity.balanceOf(writer3, oti1 + 2), 0, "oti1 writer3 assigned balance before exercise");

        assertEq(clarity.balanceOf(holder1, oti1), 2.45e6, "oti1 holder1 long balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 1), 0, "oti1 holder1 short balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti1 + 2), 0, "oti1 holder1 assigned balance before exercise");
        assertEq(clarity.balanceOf(holder2, oti1), 0.05e6, "oti1 holder2 long balance before exercise");
        assertEq(clarity.balanceOf(holder2, oti1 + 1), 0, "oti1 holder2 short balance before exercise");
        assertEq(clarity.balanceOf(holder2, oti1 + 2), 0, "oti1 holder2 assigned balance before exercise");

        // oti2
        assertEq(clarity.balanceOf(writer1, oti2), 0.05e6, "oti2 writer1 long balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti2 + 1), 1e6, "oti2 writer1 short balance before exercise");
        assertEq(clarity.balanceOf(writer1, oti2 + 2), 0, "oti2 writer1 assigned balance before exercise");

        assertEq(clarity.balanceOf(holder1, oti2), 0.95e6, "oti2 holder1 long balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti2 + 1), 0, "oti2 holder1 short balance before exercise");
        assertEq(clarity.balanceOf(holder1, oti2 + 2), 0, "oti2 holder1 assigned balance before exercise");

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.25) - (1e18 * 1),
            "writer1 WETH balance before exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer1), writer1LusdBalance, "writer1 LUSD balance before exercise");
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.25),
            "writer2 WETH balance before exercise"
        );
        assertEq(LUSDLIKE.balanceOf(writer2), writer2LusdBalance, "writer2 LUSD balance before exercise");
        assertEq(WETHLIKE.balanceOf(writer3), writer3WethBalance, "writer3 WETH balance before exercise");
        assertEq(LUSDLIKE.balanceOf(writer3), writer3LusdBalance, "writer3 LUSD balance before exercise");
        assertEq(WETHLIKE.balanceOf(holder1), holder1WethBalance, "holder1 WETH balance before exercise");
        assertEq(LUSDLIKE.balanceOf(holder1), holder1LusdBalance, "holder1 LUSD balance before exercise");
        assertEq(WETHLIKE.balanceOf(holder2), holder2WethBalance, "holder2 WETH balance before exercise");
        assertEq(LUSDLIKE.balanceOf(holder2), holder2LusdBalance, "holder2 LUSD balance before exercise");

        // warp to exercise window
        vm.warp(americanExWeeklies[0][1]);

        _;
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

    ///////// Custom Type Assertion Helpers

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

    ///////// Event Assertion Helpers

    function checkEvent_exercise_ShortsAssigned(address _writer, uint256 optionTokenId, uint80 optionAmount)
        internal
    {
        vm.expectEmit(true, true, true, true);
        emit ShortsAssigned(_writer, optionTokenId, optionAmount);
    }

    // TODO dupe for now, until Solidity 0.8.22 resolves this bug

    event OptionCreated(
        uint256 indexed optionTokenId,
        address indexed baseAsset,
        address indexed quoteAsset,
        uint32 exerciseTimestamp,
        uint32 expiryTimestamp,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    );

    event OptionsWritten(address indexed caller, uint256 indexed optionTokenId, uint80 optionAmount);

    event OptionsExercised(address indexed caller, uint256 indexed optionTokenId, uint80 optionAmount);

    event ShortsAssigned(address indexed caller, uint256 indexed optionTokenId, uint80 optionAmount);
}
