// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Test Contracts
import {MockERC20} from "./util/MockERC20.sol";

// Interfaces
import {IOption} from "../src/interface/option/IOption.sol";
import {IOptionEvents} from "../src/interface/option/IOptionEvents.sol";
import {IOptionErrors} from "../src/interface/option/IOptionErrors.sol";

// Contract Under Test
import "../src/ClarityMarkets.sol";

abstract contract BaseUnitTestSuite is Test {
    /////////

    using LibPosition for uint256;

    /////////

    // DCP
    ClarityMarkets internal clarity;

    // Actors
    address internal writer;
    address internal writer1;
    address internal writer2;
    address internal writer3;
    address internal holder;
    address internal holder1;
    address internal holder2;
    address internal holder3;

    uint256 internal constant NUM_TEST_ACTORS = 3;

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
    uint32 internal constant FRI3 = DAWN + 21 days + 1 hours; // shakes fist, darn you DST
    uint32 internal constant FRI4 = DAWN + 28 days + 1 hours;
    uint32 internal constant THU1 = DAWN + 6 days;
    uint32 internal constant THU2 = DAWN + 13 days;
    uint32 internal constant THU3 = DAWN + 20 days + 1 hours;
    uint32 internal constant THU4 = DAWN + 27 days + 1 hours;

    // uint32[] internal expiryDailies;
    // uint32[] internal expiryWeeklies;
    // uint32[] internal expiryMonthlies;
    // uint32[] internal expiryQuarterlies;

    uint32[] internal bermudanExpiriesFOW; // next 4 weeks
    uint32[] internal bermudanExpiriesFOM; // next Oct, Nov, Dec, Jan
    uint32[] internal bermudanExpiriesFOQ; // next Mar, Jun, Sep, Dec
    uint32[] internal bermudanExpiriesFOY; // next 4 years

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
        WETHLIKE = IERC20(address(new MockERC20("WETH Like", "WETH", 18)));
        WBTCLIKE = IERC20(address(new MockERC20("WBTC Like", "WBTC", 8)));
        LINKLIKE = IERC20(address(new MockERC20("LINK Like", "LINK", 18)));
        PEPELIKE = IERC20(address(new MockERC20("PEPE Like", "PEPE", 18)));
        FRAXLIKE = IERC20(address(new MockERC20("FRAX Like", "FRAX", 18)));
        LUSDLIKE = IERC20(address(new MockERC20("LUSD Like", "LUSD", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDC Like", "USDC", 6)));
        USDTLIKE = IERC20(address(new MockERC20("USDT Like", "USDT", 18)));

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
        holder = holders[0];
        holder1 = holders[0];
        holder2 = holders[1];
        holder3 = holders[2];
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
        return SafeCastLib.safeCastTo64(amount * (10 ** clarity.CONTRACT_SCALAR()));
    }

    function scaleDownOptionAmount(uint256 amount) internal view returns (uint64) {
        return SafeCastLib.safeCastTo64(amount / (10 ** clarity.CONTRACT_SCALAR()));
    }

    ///////// Custom Multi Assertions

    // Note be mindful not to add too many multi assertions and/or too much misdirection

    function assertTotalSupplies(
        uint256 optionTokenId,
        uint256 expectedOI,
        uint256 expectedAssignedShortTotalSupply,
        string memory message
    ) internal {
        assertEq(
            clarity.totalSupply(optionTokenId),
            expectedOI,
            string.concat("long total supply ", message)
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToShort()),
            expectedOI,
            string.concat("short total supply ", message)
        );
        assertEq(
            clarity.totalSupply(optionTokenId.longToAssignedShort()),
            expectedAssignedShortTotalSupply,
            string.concat("assigned short total supply ", message)
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
            string.concat("long balance ", message)
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToShort()),
            expectedShortBalance,
            string.concat("short balance ", message)
        );
        assertEq(
            clarity.balanceOf(addr, optionTokenId.longToAssignedShort()),
            expectedAssignedShortBalance,
            string.concat("assigned short balance ", message)
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
            string.concat(asset.symbol(), " balance ", message)
        );
    }

    ///////// Custom Type Assertions

    function assertEq(IOption.Option memory a, IOption.Option memory b) internal {
        assertEq(a.baseAsset, b.baseAsset);
        assertEq(a.quoteAsset, b.quoteAsset);
        assertEq(a.expiry, b.expiry);
        assertEq(a.strike, b.strike);
        assertEq(a.optionType, b.optionType);
        assertEq(a.exerciseStyle, b.exerciseStyle);
    }

    function assertEq(IOption.Option memory a, IOption.Option memory b, string memory err)
        internal
    {
        assertEq(a.baseAsset, b.baseAsset, err);
        assertEq(a.quoteAsset, b.quoteAsset, err);
        assertEq(a.expiry, b.expiry);
        assertEq(a.strike, b.strike, err);
        assertEq(a.optionType, b.optionType, err);
        assertEq(a.exerciseStyle, b.exerciseStyle, err);
    }

    function assertEq(IOption.OptionType a, IOption.OptionType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [OptionType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOption.OptionType a, IOption.OptionType b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IOption.ExerciseStyle a, IOption.ExerciseStyle b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [ExerciseStyle]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IOption.ExerciseStyle a, IOption.ExerciseStyle b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(IPosition.TokenType a, IPosition.TokenType b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [TokenType]");
            emit log_named_uint("      Left", uint8(a));
            emit log_named_uint("     Right", uint8(b));
            fail();
        }
    }

    function assertEq(IPosition.TokenType a, IPosition.TokenType b, string memory err)
        internal
    {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
}
