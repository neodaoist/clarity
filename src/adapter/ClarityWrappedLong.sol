// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/adapter/IWrappedOption.sol";
import {IClarityWrappedLong} from "../interface/adapter/IClarityWrappedLong.sol";

import {ClarityMarkets} from "../ClarityMarkets.sol";

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

        // Log ClarityERC20LongWrapperDeployed event
        // TODO
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

    function exerciseWindow() external view returns (IOptionToken.ExerciseWindow memory) {
        return clarity.option(optionTokenId).exerciseWindow;
    }

    /////////

    function wrapLongs(uint256 amount) external {
        ///////// Function Requirements
        // TODO

        ///////// Effects
        // Mint the wrapped longs to the caller
        _mint(msg.sender, amount);

        ///////// Interactions
        // Transfer the longs from the caller to the wrapper
        clarity.transferFrom(msg.sender, address(this), optionTokenId, amount);

        // Log ClarityERC20LongsWrapped event
        // TODO
    }

    function unwrapLongs(uint256 amount) external {}

    function exerciseLongs(uint256 amount) external {}
}
