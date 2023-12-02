// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// Test Contracts
import {MockERC20} from "./util/MockERC20.sol";

// Test Fixture
import "./BaseClarityTest.t.sol";

// Interfaces
import {IOption} from "../src/interface/option/IOption.sol";
import {IOptionEvents} from "../src/interface/option/IOptionEvents.sol";
import {IOptionErrors} from "../src/interface/option/IOptionErrors.sol";

abstract contract BaseUnitTest is BaseClarityTest {
    /////////

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
                    STARTING_BALANCE * (10 ** assets[j].decimals())
                );
                deal(
                    address(assets[j]),
                    holders[i],
                    STARTING_BALANCE * (10 ** assets[j].decimals())
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
}
