// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IERC6909MetadataModified {
    function names(uint256 id) external view returns (string memory);
    function symbols(uint256 id) external view returns (string memory);
    function decimals(uint256 id) external view returns (uint8);
}
