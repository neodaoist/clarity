// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../option/IOption.sol";

interface IWrappedOption {
    function optionTokenId() external view returns (uint256 optionTokenId);
    function option() external view returns (IOption.Option memory option);
}
