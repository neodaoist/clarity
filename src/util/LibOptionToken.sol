// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/option/IOptionToken.sol";

///
library LibOptionToken {
    /////////

    function hashOption(
        address baseAsset,
        address quoteAsset,
        uint40 exerciseWindows,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    ) external pure returns (uint248) {
        return uint248(
            uint256(
                keccak256(abi.encodePacked(baseAsset, quoteAsset, exerciseWindows, strikePrice, optionType))
            )
        );
    }

    function packExerciseWindows(IOptionToken.ExerciseWindow[] calldata timePairs)
        external
        pure
        returns (uint40 exerciseWindows)
    {}

    function unpackExerciseWindows(uint40 exerciseWindows)
        external
        pure
        returns (IOptionToken.ExerciseWindow[] memory timePairs)
    {}
}
