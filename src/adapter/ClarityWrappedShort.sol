// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import {IClarityWrappedShort} from "../interface/adapter/IClarityWrappedShort.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";

contract ClarityWrappedShort is IClarityWrappedShort {
    /////////

    function wrapShorts(uint256 shortAmount) external {
        revert("not yet impl");
    }

    function unwrapShorts(uint256 shortAmount) external {
        revert("not yet impl");
    }

    function redeemShorts(uint256 shortAmount) external {
        revert("not yet impl");
    }
}
