// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC6909MetadataModified.sol";

interface IERC6909MetadataURI is IERC6909MetadataModified {
    function tokenURI(uint256 id) external view returns (string memory);
}
