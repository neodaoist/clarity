// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC6909ContentURI {
    function contractURI() external view returns (string memory);
    function tokenURI(uint256 id) external view returns (string memory);
}
