// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IOption} from "./IOption.sol";

interface IOptionViews {
    function optionTokenId(address baseAsset, address quoteAsset, uint32[] calldata exerciseWindow, uint256 strikePrice, bool isCall) external view returns (uint256 optionTokenId);
    function option(uint256 optionTokenId) external view returns (IOption.Option memory option);
}
