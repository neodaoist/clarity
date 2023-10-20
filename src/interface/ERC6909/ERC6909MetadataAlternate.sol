// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract ERC6909MetadataAlternate {
    /// @notice The name for each id.
    mapping(uint256 id => string name) public names;

    /// @notice The symbol for each id.
    mapping(uint256 id => string symbol) public symbols;

    /// @notice The number of decimals for each id.
    mapping(uint256 id => uint8 amount) public decimals;
}
