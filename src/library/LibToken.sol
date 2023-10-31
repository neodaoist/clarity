// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import {IOptionToken} from "../interface/option/IOptionToken.sol";

library LibToken {
    /////////

    ///////// Token ID

    function paramsToHash(
        address baseAsset,
        address quoteAsset,
        uint32[] memory exerciseWindow,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    ) internal pure returns (uint248) {
        return uint248(
            bytes31(keccak256(abi.encode(baseAsset, quoteAsset, exerciseWindow, strikePrice, optionType)))
        );
    }

    function hashToId(uint248 instrumentHash) internal pure returns (uint256) {
        return uint256(instrumentHash) << 8;
    }

    function idToHash(uint256 tokenId) internal pure returns (uint248) {
        return uint248(tokenId >> 8);
    }

    function longToShort(uint256 tokenId) internal pure returns (uint256) {
        return tokenId | 1;
    }

    function longToAssignedShort(uint256 tokenId) internal pure returns (uint256) {
        return tokenId | 2;
    }

    function shortToLong(uint256 tokenId) internal pure returns (uint256) {
        return tokenId ^ 1;
    }

    function assignedShortToLong(uint256 tokenId) internal pure returns (uint256) {
        return tokenId ^ 2;
    }

    function assignedShortToShort(uint256 tokenId) internal pure returns (uint256) {
        return (tokenId ^ 2) | 1;
    }

    function tokenType(uint256 tokenId) internal pure returns (IOptionToken.TokenType) {
        return IOptionToken.TokenType(tokenId & 0xFF);
    }

    ///////// Exercise Style

    // TODO more thinking on European exercise, what this really means -- **no** early assignment risk for writers
    // TODO should this all be in one library
    // TODO add Bermudan support

    function determineExerciseStyle(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOptionToken.ExerciseStyle exerciseStyle)
    {
        if (exerciseWindows[1] - exerciseWindows[0] <= 1 hours) {
            exerciseStyle = IOptionToken.ExerciseStyle.EUROPEAN;
        } else {
            exerciseStyle = IOptionToken.ExerciseStyle.AMERICAN;
        }
    }

    ///////// Exercise Window

    function toExerciseWindow(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOptionToken.ExerciseWindow memory timePair)
    {
        // timePairs = new IOptionToken.ExerciseWindow[](exerciseWindows.length / 2);

        // for (uint256 i = 0; i < exerciseWindows.length; i += 2) {
        //     timePairs[i / 2] = IOptionToken.ExerciseWindow(exerciseWindows[i], exerciseWindows[i + 1]);
        // }

        timePair = IOptionToken.ExerciseWindow(exerciseWindows[0], exerciseWindows[1]);
    }

    function fromExerciseWindow(IOptionToken.ExerciseWindow calldata timePair)
        external
        pure
        returns (uint32[] memory exerciseWindows)
    {}
}
