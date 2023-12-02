// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Helpers
import {Test, console2, stdError} from "forge-std/Test.sol";

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Helpers
import {Assertions} from "./util/Assertions.sol";

// Test Contracts
import {MockERC20} from "./util/MockERC20.sol";

// Contracts
import "../src/ClarityMarkets.sol";

abstract contract BaseClarityTest is Test, Assertions {
    /////////

    // Time
    uint32 internal constant DAWN = 1_697_788_800; // Fri Oct 20 2023 08:00:00 GMT+0000

    // Assets
    // Volatile / Base Assets
    IERC20[] internal baseAssets;
    IERC20 internal WETHLIKE;
    IERC20 internal WBTCLIKE;
    IERC20 internal LINKLIKE;
    IERC20 internal PEPELIKE;
    // Stable / Quote Assets
    IERC20[] internal quoteAssets;
    IERC20 internal FRAXLIKE;
    IERC20 internal LUSDLIKE;
    IERC20 internal USDCLIKE;
    IERC20 internal USDTLIKE; // TODO add idiosyncrasies

    // Contract Under Test
    ClarityMarkets internal clarity;

    ///////// Setup

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
        LUSDLIKE = IERC20(address(new MockERC20("LUSD Like", "LUSD", 18)));
        FRAXLIKE = IERC20(address(new MockERC20("FRAX Like", "FRAX", 18)));
        USDCLIKE = IERC20(address(new MockERC20("USDC Like", "USDC", 6)));
        USDTLIKE = IERC20(address(new MockERC20("USDT Like", "USDT", 18)));
        vm.label(address(WETHLIKE), "WETH");
        vm.label(address(WBTCLIKE), "WBTC");
        vm.label(address(LINKLIKE), "LINK");
        vm.label(address(PEPELIKE), "PEPE");
        vm.label(address(LUSDLIKE), "LUSD");
        vm.label(address(FRAXLIKE), "FRAX");
        vm.label(address(USDCLIKE), "USDC");
        vm.label(address(USDTLIKE), "USDT");
        baseAssets.push(WETHLIKE);
        baseAssets.push(WBTCLIKE);
        baseAssets.push(LINKLIKE);
        baseAssets.push(PEPELIKE);
        quoteAssets.push(FRAXLIKE);
        quoteAssets.push(LUSDLIKE);
        quoteAssets.push(USDCLIKE);
        quoteAssets.push(USDTLIKE);
    }
}
