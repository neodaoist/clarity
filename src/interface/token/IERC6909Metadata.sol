// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC6909Metadata {
    function name(uint256 id) external view returns (string memory);
    function symbol(uint256 id) external view returns (string memory);
    function decimals(uint256 id) external view returns (uint8);
}
