// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import {IClarityWrappedShort} from "../interface/adapter/IClarityWrappedShort.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";

contract ClarityWrappedShort is IClarityWrappedShort {
    /////////

    function wrapShorts(uint64 /*shortAmount*/) external pure {
        revert("not yet impl");
    }

    function unwrapShorts(uint64 /*shortAmount*/) external pure {
        revert("not yet impl");
    }

    function redeemShorts(uint64 /*shortAmount*/) external pure {
        revert("not yet impl");
    }
}
