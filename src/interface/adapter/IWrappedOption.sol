// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import {IOptionToken} from "../option/IOptionToken.sol";

interface IWrappedOption {
    function optionTokenId() external view returns (uint256 optionTokenId);
    function option() external view returns (IOptionToken.Option memory option);
}
