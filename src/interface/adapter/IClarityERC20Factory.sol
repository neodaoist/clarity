// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityERC20Factory {
    function wrapperFor(uint256 tokenId) external view returns (address wrapperAddress);
    function deployWrappedLong(uint256 longTokenId) external returns (address wrapperAddress);
    function deployWrappedShort(uint256 shortTokenId) external returns (address wrapperAddress);
}