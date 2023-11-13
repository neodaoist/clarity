// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IPosition} from "../interface/IPosition.sol";
import {IOption} from "../interface/option/IOption.sol";
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";
import {IClarityERC20Factory} from "../interface/adapter/IClarityERC20Factory.sol";

// Libraries
import {LibPosition} from "../library/LibPosition.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";
import {ClarityWrappedLong} from "./ClarityWrappedLong.sol";
import {ClarityWrappedShort} from "./ClarityWrappedShort.sol";

contract ClarityERC20Factory is IClarityERC20Factory {
    /////////

    using LibPosition for uint256;

    mapping(uint256 => address) public wrapperFor;

    ClarityMarkets public immutable clarity;

    constructor(ClarityMarkets _clarity) {
        clarity = _clarity;
    }

    ///////// Functions

    function deployWrappedLong(uint256 optionTokenId)
        external
        returns (address wrapperAddress)
    {
        ///////// Function Requirements
        // Check that the option exists
        IOption.Option memory option = clarity.option(optionTokenId);
        if (option.baseAsset == address(0)) {
            revert IOptionErrors.OptionDoesNotExist(optionTokenId);
        }

        // Check that the option is not already wrapped
        if (wrapperFor[optionTokenId] != address(0)) {
            revert IOptionErrors.WrappedLongAlreadyDeployed(optionTokenId);
        }

        // Check that the option is not expired
        if (block.timestamp > option.exerciseWindow.expiryTimestamp) {
            revert IOptionErrors.OptionExpired(optionTokenId, uint32(block.timestamp));
        }

        ///////// Effects
        // TODO precompute address and move state change here

        ///////// Interactions
        // Deploy a new ClarityWrappedLong contract
        string memory wrappedName = string.concat("w", clarity.names(optionTokenId));
        ClarityWrappedLong wrapper =
            new ClarityWrappedLong(clarity, optionTokenId, wrappedName);
        wrapperAddress = address(wrapper);

        // Store the deployed address for the wrapper
        wrapperFor[optionTokenId] = wrapperAddress;
    }

    function deployWrappedShort(uint256 shortTokenId)
        external
        returns (address wrapperAddress)
    {
        ///////// Function Requirements
        // Check that the token type is a short
        if (shortTokenId.tokenType() != IPosition.TokenType.SHORT) {
            revert IOptionErrors.TokenIdNotShort(shortTokenId);
        }

        // Check that the option exists
        uint256 optionTokenId = shortTokenId.shortToLong();
        IOption.Option memory option = clarity.option(optionTokenId);
        if (option.baseAsset == address(0)) {
            revert IOptionErrors.OptionDoesNotExist(optionTokenId);
        }

        // Check that the option is not already wrapped
        if (wrapperFor[shortTokenId] != address(0)) {
            revert IOptionErrors.WrappedShortAlreadyDeployed(shortTokenId);
        }

        // Check that the option is not expired
        if (block.timestamp > option.exerciseWindow.expiryTimestamp) {
            revert IOptionErrors.OptionExpired(optionTokenId, uint32(block.timestamp));
        }

        // Check that the short has not been assigned
        if (clarity.totalSupply(shortTokenId.shortToAssignedShort()) > 0) {
            revert IOptionErrors.ShortAlreadyAssigned(shortTokenId);
        }

        ///////// Effects
        // TODO precompute address and move state change here

        ///////// Interactions
        // Deploy a new ClarityWrappedLong contract
        string memory wrappedName = string.concat("w", clarity.names(shortTokenId));
        ClarityWrappedShort wrapper =
            new ClarityWrappedShort(clarity, shortTokenId, wrappedName);
        wrapperAddress = address(wrapper);

        // Store the deployed address for the wrapper
        wrapperFor[shortTokenId] = wrapperAddress;
    }
}
