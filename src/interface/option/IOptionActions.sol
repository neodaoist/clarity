// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionActions {
    function writeCall(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint80 optionAmount
    ) external returns (uint256 optionTokenId);
    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint80 optionAmount
    ) external returns (uint256 optionTokenId);
    function write(uint256 optionTokenId, uint80 optionAmount) external;
    function batchWrite(uint256[] calldata optionTokenIds, uint80[] calldata optionAmounts) external;
    function exercise(uint256 optionTokenId, uint80 optionAmount) external;
    function netOff(uint256 optionTokenId, uint80 optionAmount)
        external
        returns (uint256 writeAssetNettedOff); // TODO width needs to change
    function redeem(uint256 optionTokenId)
        external
        returns (uint176 writeAssetRedeemed, uint176 exerciseAssetRedeemed); // TODO width needs to change
}
