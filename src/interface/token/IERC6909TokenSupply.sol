// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC6909TokenSupply {
    function totalSupply(uint256 id) external view returns (uint256);
}
