// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionActions {
    function writeCall(
        address baseAsset,
        uint56 baseAmount,
        address quoteAsset,
        uint56 quoteAmount,
        uint40 exerciseWindows,
        uint80 optionAmount
    ) external returns (uint256 optionTokenId);
    function writePut(
        address baseAsset,
        uint56 baseAmount,
        address quoteAsset,
        uint56 quoteAmount,
        uint40 exerciseWindows,
        uint80 optionAmount
    ) external returns (uint256 optionTokenId);
    function write(uint256 optionTokenId, uint80 optionAmount) external;
    function batchWrite(uint256[] calldata optionTokenIds, uint80[] calldata optionAmounts)
        external;
    function exercise(uint256 optionTokenId, uint80 optionAmount) external;
    function netoff(uint256 optionTokenId, uint80 optionAmount)
        external
        returns (uint176 writeAssetNettedOff);
    function redeem(uint256 optionTokenId)
        external
        returns (uint176 writeAssetRedeemed, uint176 exerciseAssetRedeemed);
}
