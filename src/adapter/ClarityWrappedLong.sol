// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import {IOptionToken} from "../interface/option/IOptionToken.sol";
import {IWrappedOption} from "../interface/adapter/IWrappedOption.sol";
import {IClarityWrappedLong} from "../interface/adapter/IClarityWrappedLong.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";
import {OptionErrors} from "../library/OptionErrors.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ClarityWrappedLong is IWrappedOption, IClarityWrappedLong, ERC20 {
    /////////

    ClarityMarkets public immutable clarity;

    uint256 public immutable optionTokenId;

    constructor(ClarityMarkets _clarity, uint256 _optionTokenId, string memory _name)
        ERC20(_name, _name, 6)
    {
        // Set state
        clarity = _clarity;
        optionTokenId = _optionTokenId;

        // Log event
        emit ClarityWrappedLongDeployed(_optionTokenId, address(this));
    }

    /////////

    function option() external view returns (IOptionToken.Option memory) {
        return clarity.option(optionTokenId);
    }

    function optionType() external view returns (IOptionToken.OptionType) {
        return clarity.optionType(optionTokenId);
    }

    function exerciseStyle() external view returns (IOptionToken.ExerciseStyle) {
        return clarity.exerciseStyle(optionTokenId);
    }

    function exerciseWindow()
        external
        view
        returns (IOptionToken.ExerciseWindow memory)
    {
        return clarity.option(optionTokenId).exerciseWindow;
    }

    /////////

    function wrapLongs(uint64 optionAmount) external {
        ///////// Function Requirements
        // Check that the option amount is not zero
        if (optionAmount == 0) {
            revert OptionErrors.WrapAmountZero();
        }

        // Check that the option is not expired
        IOptionToken.Option memory _option = clarity.option(optionTokenId);
        if (block.timestamp > _option.exerciseWindow.expiryTimestamp) {
            revert OptionErrors.OptionExpired(optionTokenId, uint32(block.timestamp));
        }

        // Check that the caller holds sufficient longs of this option
        uint256 optionBalance = clarity.balanceOf(msg.sender, optionTokenId);
        if (optionBalance < optionAmount) {
            revert OptionErrors.InsufficientLongBalance(optionTokenId, optionBalance);
        }

        ///////// Effects
        // Mint the wrapped longs to the caller
        _mint(msg.sender, optionAmount);

        ///////// Interactions
        // Transfer the longs from the caller to the wrapper
        clarity.transferFrom(msg.sender, address(this), optionTokenId, optionAmount);

        // Log event
        emit ClarityLongsWrapped(msg.sender, optionTokenId, optionAmount);
    }

    function unwrapLongs(uint64 optionAmount) external {
        ///////// Function Requirements
        // Check that the option amount is not zero
        if (optionAmount == 0) {
            revert OptionErrors.UnwrapAmountZero();
        }

        // Check that the caller holds sufficient wrapped longs of this option
        uint256 wrappedBalance = balanceOf[msg.sender];
        if (wrappedBalance < optionAmount) {
            revert OptionErrors.InsufficientWrappedBalance(optionTokenId, wrappedBalance);
        }

        ///////// Effects
        // Burn the wrapped longs from the caller
        _burn(msg.sender, optionAmount);

        ///////// Interactions
        // Transfer the longs from the wrapper to the caller
        clarity.transfer(msg.sender, optionTokenId, optionAmount);

        // Log event
        emit ClarityLongsUnwrapped(msg.sender, optionTokenId, optionAmount);
    }

    function exerciseLongs(uint64 /*optionAmount*/) external pure {
        revert("not yet impl");
    }
}
