// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IClarityERC20Factory} from "../interface/adapter/IClarityERC20Factory.sol";

import {ClarityMarkets} from "../ClarityMarkets.sol";
import {ClarityWrappedLong} from "./ClarityWrappedLong.sol";
import {ClarityWrappedShort} from "./ClarityWrappedShort.sol";

contract ClarityERC20Factory is IClarityERC20Factory {
    /////////

    mapping(uint256 => address) public wrapperFor;

    ClarityMarkets public immutable clarity;

    constructor(ClarityMarkets _clarity) {
        clarity = _clarity;
    }

    /////////

    function deployWrappedLong(uint256 optionTokenId) external returns (address wrapperAddress) {
        ///////// Function Requirements
        // Check that the option exists

        // Check that the option is not already wrapped

        // Check that the option is not expired

        // Check that the caller holds sufficient longs of this option

        ///////// Effects
        // TODO precompute address and move state change here

        ///////// Interactions
        // Deploy a new ClarityWrappedLong contract
        string memory wrappedName = string(abi.encodePacked("w", clarity.names(optionTokenId)));
        ClarityWrappedLong wrapper = new ClarityWrappedLong(clarity, optionTokenId, wrappedName);
        wrapperAddress = address(wrapper);

        // Store the deployed address for the wrapper
        wrapperFor[optionTokenId] = wrapperAddress;
    }

    function deployWrappedShort(uint256 shortTokenId) external returns (address wrapperAddress) {
        ///////// Function Requirements

        ///////// Effects

        ///////// Interactions
    }
}
