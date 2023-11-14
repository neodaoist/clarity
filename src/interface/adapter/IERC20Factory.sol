// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IERC20Factory {
    function wrapperFor(uint256 tokenId) external view returns (address wrapperAddress);
    function deployWrappedLong(uint256 optionTokenId)
        external
        returns (address wrapperAddress);
    function deployWrappedShort(uint256 shortTokenId)
        external
        returns (address wrapperAddress);
}
