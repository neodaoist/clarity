// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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

    // Time
    uint32 internal constant FRI1 = DAWN + 7 days;
    uint32 internal constant FRI2 = DAWN + 14 days;
    uint32 internal constant FRI3 = DAWN + 21 days + 1 hours; // DST
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

    function setUp() public virtual override {
        super.setUp();

        // make test actors and mint 1e6 of each asset
        address[] memory writers = new address[](3);
        address[] memory holders = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            writers[i] = makeAddress(string(abi.encodePacked("writer", i + 1)));
            holders[i] = makeAddress(string(abi.encodePacked("holder", i + 1)));

            for (uint256 j = 0; j < baseAssets.length; j++) {
                deal(
                    address(baseAssets[j]),
                    writers[i],
                    1e6 * (10 ** baseAssets[j].decimals())
                );
                deal(
                    address(baseAssets[j]),
                    holders[i],
                    1e6 * (10 ** baseAssets[j].decimals())
                );
            }

            for (uint256 j = 0; j < quoteAssets.length; j++) {
                deal(
                    address(quoteAssets[j]),
                    writers[i],
                    1e6 * (10 ** quoteAssets[j].decimals())
                );
                deal(
                    address(quoteAssets[j]),
                    holders[i],
                    1e6 * (10 ** quoteAssets[j].decimals())
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
