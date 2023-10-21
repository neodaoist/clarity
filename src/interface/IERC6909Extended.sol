// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./external/IERC6909Metadata.sol";
import "./external/IERC6909MetadataURI.sol";
import "./external/IERC6909Ownership.sol";

interface IERC6909Extended is IERC6909Metadata, IERC6909MetadataURI, IERC6909Ownership {}
