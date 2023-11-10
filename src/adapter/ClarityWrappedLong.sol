// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";
import {IWrappedOption} from "../interface/adapter/IWrappedOption.sol";
import {IClarityWrappedLong} from "../interface/adapter/IClarityWrappedLong.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ClarityWrappedLong is IWrappedOption, IClarityWrappedLong, ERC20 {
    /////////

    ClarityMarkets public immutable clarity;

    uint256 public immutable optionTokenId;

    uint8 private constant DECIMALS = 6;

    constructor(ClarityMarkets _clarity, uint256 _optionTokenId, string memory _name)
        ERC20(_name, _name, DECIMALS)
    {
        // Set state
        clarity = _clarity;
        optionTokenId = _optionTokenId;

        // Log event
        emit ClarityWrappedLongDeployed(_optionTokenId, address(this));
    }

    /////////

    function option() external view returns (IOption.Option memory) {
        return clarity.option(optionTokenId);
    }

    /////////

    function wrapLongs(uint64 optionAmount) external {
        ///////// Function Requirements
        // Check that the option amount is not zero
        if (optionAmount == 0) {
            revert IOptionErrors.WrapAmountZero();
        }

        // Check that the option is not expired
        IOption.Option memory _option = clarity.option(optionTokenId);
        if (block.timestamp > _option.exerciseWindow.expiryTimestamp) {
            revert IOptionErrors.OptionExpired(optionTokenId, uint32(block.timestamp));
        }

        // Check that the caller holds sufficient longs of this option
        uint256 optionBalance = clarity.balanceOf(msg.sender, optionTokenId);
        if (optionBalance < optionAmount) {
            revert IOptionErrors.InsufficientLongBalance(optionTokenId, optionBalance);
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
            revert IOptionErrors.UnwrapAmountZero();
        }

        // Check that the caller holds sufficient wrapped longs of this option
        uint256 wrappedBalance = balanceOf[msg.sender];
        if (wrappedBalance < optionAmount) {
            revert IOptionErrors.InsufficientWrappedBalance(optionTokenId, wrappedBalance);
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

    function exerciseLongs(uint64 /*optionAmount*/ ) external pure {
        revert("not yet impl");
    }
}
