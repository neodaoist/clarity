// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Test Contracts
import {MockERC20} from "./util/MockERC20.sol";

// Interfaces
import {IOptionToken} from "../src/interface/option/IOptionToken.sol";
import {IOptionEvents} from "../src/interface/option/IOptionEvents.sol";

// Contract Under Test
import "../src/ClarityMarkets.sol";

abstract contract BaseClarityMarketsTest is Test {
    /////////

    using LibToken for uint256;

    // DCP
    ClarityMarkets internal clarity;

    // Actors
    // TODO improve actor test fixture(s)

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

    uint256 internal constant NUM_TEST_ACTORS = 10;

    // Assets
    // volatile
    IERC20 internal WETHLIKE;
    IERC20 internal WBTCLIKE;
    IERC20 internal LINKLIKE;
    IERC20 internal PEPELIKE;
    // stable
    IERC20 internal FRAXLIKE;
    IERC20 internal LUSDLIKE;
    IERC20 internal USDCLIKE;
    IERC20 internal USDTLIKE;

    uint256 internal constant NUM_TEST_ASSETS = 8;
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

    function setUp() public virtual {
        // dawn
        vm.warp(DAWN);

        // deploy DCP
        clarity = new ClarityMarkets();

        // deploy test assets
        WETHLIKE = IERC20(address(new MockERC20("WETH Like", "WETHLIKE", 18)));
        WBTCLIKE = IERC20(address(new MockERC20("WBTC Like", "WBTCLIKE", 8)));
        LINKLIKE = IERC20(address(new MockERC20("LINK Like", "LINKLIKE", 18)));
        PEPELIKE = IERC20(address(new MockERC20("PEPE Like", "PEPELIKE", 18)));
        FRAXLIKE = IERC20(address(new MockERC20("FRAX Like", "FRAXLIKE", 18)));
        LUSDLIKE = IERC20(address(new MockERC20("LUSD Like", "LUSDLIKE", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDC Like", "USDCLIKE", 6)));
        USDTLIKE = IERC20(address(new MockERC20("USDT Like", "USDTLIKE", 18)));

        // make test actors and mint assets
        address[] memory writers = new address[](NUM_TEST_ACTORS);
        address[] memory holders = new address[](NUM_TEST_ACTORS);
        IERC20[] memory assets = new IERC20[](NUM_TEST_ASSETS);
        assets[0] = WETHLIKE;
        assets[1] = WBTCLIKE;
        assets[2] = LINKLIKE;
        assets[3] = PEPELIKE;
        assets[4] = FRAXLIKE;
        assets[5] = LUSDLIKE;
        assets[6] = USDCLIKE;
        assets[7] = USDTLIKE;
        for (uint256 i = 0; i < NUM_TEST_ACTORS; i++) {
            writers[i] = makeAddress(string(abi.encodePacked("writer", i + 1)));
            holders[i] = makeAddress(string(abi.encodePacked("holder", i + 1)));

            for (uint256 j = 0; j < NUM_TEST_ASSETS; j++) {
                deal(
                    address(assets[j]),
                    writers[i],
                    scaleUpAssetAmount(assets[j], STARTING_BALANCE)
                );
                deal(
                    address(assets[j]),
                    holders[i],
                    scaleUpAssetAmount(assets[j], STARTING_BALANCE)
                );
            }
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
        // American
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

        // European
        europeanExWeeklies = new uint32[][](4);
        europeanExWeeklies[0] = new uint32[](2);
        europeanExWeeklies[1] = new uint32[](2);
        europeanExWeeklies[2] = new uint32[](2);
        europeanExWeeklies[3] = new uint32[](2);
        europeanExWeeklies[0][0] = FRI1 - 1 hours;
        europeanExWeeklies[0][1] = FRI1;
        europeanExWeeklies[1][0] = FRI2 - 1 hours;
        europeanExWeeklies[1][1] = FRI2;
        europeanExWeeklies[2][0] = FRI3 - 1 hours;
        europeanExWeeklies[2][1] = FRI3;
        europeanExWeeklies[3][0] = FRI4 - 1 hours;
        europeanExWeeklies[3][1] = FRI4;
    }

    ///////// Test Backgrounds

    modifier withSimpleBackground() {
        uint32[] memory exerciseWindow = new uint32[](2);
        exerciseWindow[0] = FRI1 + 1 seconds;
        exerciseWindow[1] = FRI2;

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
            address(WETHLIKE), address(LUSDLIKE), exerciseWindow, 1750e18, 0.15e6
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
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 1),
            2.15e6,
            "oti1 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 2),
            0,
            "oti1 writer1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 1),
            0.35e6,
            "oti1 writer2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 2),
            0,
            "oti1 writer2 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.5e6,
            "oti1 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 1),
            0,
            "oti1 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 2),
            0,
            "oti1 holder1 assigned balance before exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.15),
            "writer1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer1),
            writer1LusdBalance,
            "writer1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.35),
            "writer2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer2),
            writer2LusdBalance,
            "writer2 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance,
            "holder1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance,
            "holder1 LUSD balance before exercise"
        );

        // warp to exercise window
        vm.warp(FRI1 + 1 seconds);

        _;
    }

    modifier withMediumBackground(uint256 writes) {
        // TODO

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
        oti1 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1700e18, 1.25e6
        );
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
        oti2 = clarity.writeCall(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, 1e6
        );

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
        assertEq(
            clarity.balanceOf(writer1, oti1),
            0,
            "oti1 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 1),
            1.75e6,
            "oti1 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti1 + 2),
            0,
            "oti1 writer1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1),
            0,
            "oti1 writer2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 1),
            0.25e6,
            "oti1 writer2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer2, oti1 + 2),
            0,
            "oti1 writer2 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1),
            0,
            "oti1 writer3 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1 + 1),
            0.5e6,
            "oti1 writer3 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer3, oti1 + 2),
            0,
            "oti1 writer3 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti1),
            2.45e6,
            "oti1 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 1),
            0,
            "oti1 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti1 + 2),
            0,
            "oti1 holder1 assigned balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1),
            0.05e6,
            "oti1 holder2 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1 + 1),
            0,
            "oti1 holder2 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder2, oti1 + 2),
            0,
            "oti1 holder2 assigned balance before exercise"
        );

        // oti2
        assertEq(
            clarity.balanceOf(writer1, oti2),
            0.05e6,
            "oti2 writer1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti2 + 1),
            1e6,
            "oti2 writer1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(writer1, oti2 + 2),
            0,
            "oti2 writer1 assigned balance before exercise"
        );

        assertEq(
            clarity.balanceOf(holder1, oti2),
            0.95e6,
            "oti2 holder1 long balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti2 + 1),
            0,
            "oti2 holder1 short balance before exercise"
        );
        assertEq(
            clarity.balanceOf(holder1, oti2 + 2),
            0,
            "oti2 holder1 assigned balance before exercise"
        );

        // check asset balances
        assertEq(
            WETHLIKE.balanceOf(writer1),
            writer1WethBalance - (1e18 * 2.25) - (1e18 * 1),
            "writer1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer1),
            writer1LusdBalance,
            "writer1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer2),
            writer2WethBalance - (1e18 * 0.25),
            "writer2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer2),
            writer2LusdBalance,
            "writer2 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(writer3),
            writer3WethBalance,
            "writer3 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(writer3),
            writer3LusdBalance,
            "writer3 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder1),
            holder1WethBalance,
            "holder1 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder1),
            holder1LusdBalance,
            "holder1 LUSD balance before exercise"
        );
        assertEq(
            WETHLIKE.balanceOf(holder2),
            holder2WethBalance,
            "holder2 WETH balance before exercise"
        );
        assertEq(
            LUSDLIKE.balanceOf(holder2),
            holder2LusdBalance,
            "holder2 LUSD balance before exercise"
        );

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

    function scaleUpAssetAmount(IERC20 token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount * (10 ** token.decimals());
    }

    function scaleDownAssetAmount(IERC20 token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount / (10 ** token.decimals());
    }

    function scaleUpOptionAmount(uint256 amount) internal view returns (uint64) {
        return SafeCastLib.safeCastTo64(amount * (10 ** clarity.OPTION_CONTRACT_SCALAR()));
    }

    function scaleDownOptionAmount(uint256 amount) internal view returns (uint64) {
        return SafeCastLib.safeCastTo64(amount / (10 ** clarity.OPTION_CONTRACT_SCALAR()));
    }

    ///////// Custom Multi Assertions
    // Note be mindful not to add too many multi assertions and/or too much misdirection

    function assertTotalSupplies(
        uint256 optionTokenId,
        uint256 expectedLongTotalSupply,
        uint256 expectedShortTotalSupply,
        uint256 expectedAssignedShortTotalSupply,
        string memory message
    ) internal {
        assertEq(
            clarity.totalSupply(optionTokenId),
            expectedLongTotalSupply,
            string(abi.encodePacked("long total supply ", message))
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToShort()),
            expectedShortTotalSupply,
            string(abi.encodePacked("short total supply ", message))
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToAssignedShort()),
            expectedAssignedShortTotalSupply,
            string(abi.encodePacked("assigned short total supply ", message))
        );
    }

    function assertOptionBalances(
        address addr,
        uint256 optionTokenId,
        uint256 expectedLongBalance,
        uint256 expectedShortBalance,
        uint256 expectedAssignedShortBalance,
        string memory message
    ) internal {
        assertEq(
            clarity.balanceOf(addr, optionTokenId),
            expectedLongBalance,
            string(abi.encodePacked("long balance ", message))
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToShort()),
            expectedShortBalance,
            string(abi.encodePacked("short balance ", message))
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToAssignedShort()),
            expectedAssignedShortBalance,
            string(abi.encodePacked("assigned short balance ", message))
        );
    }

    function assertAssetBalance(
        address addr,
        IERC20 asset,
        uint256 expectedBalance,
        string memory message
    ) internal {
        assertEq(
            asset.balanceOf(addr),
            expectedBalance,
            string(abi.encodePacked(asset.symbol(), " balance ", message))
        );
    }

    ///////// Custom Type Assertions

    // TODO add assertion for Option itself

    function assertEq(IOptionToken.OptionType a, IOptionToken.OptionType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [OptionType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(
        IOptionToken.OptionType a,
        IOptionToken.OptionType b,
        string memory err
    ) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOptionToken.ExerciseStyle a, IOptionToken.ExerciseStyle b)
        internal
    {
        if (a != b) {
            emit log("Error: a == b not satisfied [ExerciseStyle]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(
        IOptionToken.ExerciseStyle a,
        IOptionToken.ExerciseStyle b,
        string memory err
    ) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(
        IOptionToken.ExerciseWindow memory a,
        IOptionToken.ExerciseWindow memory b
    ) internal {
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
        if (
            a.exerciseTimestamp != b.exerciseTimestamp
                || a.expiryTimestamp != b.expiryTimestamp
        ) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOptionToken.TokenType a, IOptionToken.TokenType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [TokenType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(
        IOptionToken.TokenType a,
        IOptionToken.TokenType b,
        string memory err
    ) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
}
