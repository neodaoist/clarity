// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC6909/IERC6909Metadata.sol";
import "./ERC6909/IERC6909MetadataURI.sol";
import "./ERC6909/IERC6909Ownership.sol";

interface IERC6909Extended is IERC6909Metadata, IERC6909MetadataURI, IERC6909Ownership {}
