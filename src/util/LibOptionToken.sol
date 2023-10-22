// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/option/IOptionToken.sol";

///
library LibOptionToken {
    /////////

    function hashOption(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    ) external pure returns (uint248) {
        return uint248(
            uint256(
                keccak256(abi.encodePacked(baseAsset, quoteAsset, exerciseWindows, strikePrice, optionType))
            )
        );
    }

    function toExerciseWindows(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOptionToken.ExerciseWindow[] memory timePairs)
    {
        timePairs = new IOptionToken.ExerciseWindow[](exerciseWindows.length / 2);

        for (uint256 i = 0; i < exerciseWindows.length; i += 2) {
            timePairs[i / 2] = IOptionToken.ExerciseWindow(exerciseWindows[i], exerciseWindows[i + 1]);
        }
    }

    function fromExerciseWindows(IOptionToken.ExerciseWindow[] calldata timePairs)
        external
        pure
        returns (uint64[] memory exerciseWindows)
    {}
}
