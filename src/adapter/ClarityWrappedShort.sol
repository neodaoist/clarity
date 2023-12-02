// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";
import {IWrappedOption} from "../interface/adapter/IWrappedOption.sol";
import {IWrappedShortActions} from "../interface/adapter/IWrappedShortActions.sol";
import {IWrappedShortEvents} from "../interface/adapter/IWrappedShortEvents.sol";

// Libraries
import {LibPosition} from "../library/LibPosition.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ClarityWrappedShort is
    IWrappedOption,
    IWrappedShortActions,
    IWrappedShortEvents,
    ERC20
{
    /////////

    using LibPosition for uint256;

    /////////

    ClarityMarkets public immutable clarity;

    uint256 public immutable optionTokenId;

    uint256 public immutable shortTokenId;

    /////////

    uint8 private constant DECIMALS = 6;

    constructor(ClarityMarkets _clarity, uint256 _shortTokenId, string memory _name)
        ERC20(_name, _name, DECIMALS)
    {
        // Set state
        clarity = _clarity;
        optionTokenId = _shortTokenId.shortToLong();
        shortTokenId = _shortTokenId;

        // Log event
        emit ClarityWrappedShortDeployed(_shortTokenId, address(this));
    }

    ///////// Views

    function option() external view returns (IOption.Option memory) {
        return clarity.option(optionTokenId);
    }

    ///////// Functions

    function wrapShorts(uint64 shortAmount) external {
        ///////// Function Requirements
        // Check that the short amount is not zero
        if (shortAmount == 0) {
            revert IOptionErrors.WrapAmountZero();
        }

        // Check that the option is not expired
        IOption.Option memory _option = clarity.option(optionTokenId);
        if (block.timestamp > _option.expiry) {
            revert IOptionErrors.OptionExpired(optionTokenId, uint32(block.timestamp));
        }

        // Check that the caller holds sufficient shorts of this option
        uint256 shortBalance = clarity.balanceOf(msg.sender, shortTokenId);
        if (shortBalance < shortAmount) {
            revert IOptionErrors.InsufficientShortBalance(shortTokenId, shortBalance);
        }

        ///////// Effects
        // Mint the wrapped shorts to the caller
        _mint(msg.sender, shortAmount);

        ///////// Interactions
        // Transfer the shorts from the caller to the wrapper
        clarity.transferFrom(msg.sender, address(this), shortTokenId, shortAmount);

        // Log event
        emit ClarityShortsWrapped(msg.sender, shortTokenId, shortAmount);
    }

    function unwrapShorts(uint64 shortAmount) external {
        ///////// Function Requirements
        // Check that the option amount is not zero
        if (shortAmount == 0) {
            revert IOptionErrors.UnwrapAmountZero();
        }

        // Check that the caller holds sufficient wrapped shorts of this option
        uint256 wrappedBalance = balanceOf[msg.sender];
        if (wrappedBalance < shortAmount) {
            revert IOptionErrors.InsufficientWrappedBalance(shortTokenId, wrappedBalance);
        }

        ///////// Effects
        // Burn the wrapped shorts from the caller
        _burn(msg.sender, shortAmount);

        ///////// Interactions
        // Transfer the shorts from the wrapper to the caller
        clarity.transfer(msg.sender, shortTokenId, shortAmount);

        // Log event
        emit ClarityShortsUnwrapped(msg.sender, shortTokenId, shortAmount);
    }

    function redeemCollateral(uint64 /*shortAmount*/ ) external pure {
        revert("not yet impl"); // TODO
    }
}
