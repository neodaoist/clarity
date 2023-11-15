// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC6909MetadataURI {
    function tokenURI(uint256 id) external view returns (string memory);
}
