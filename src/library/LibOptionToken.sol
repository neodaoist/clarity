// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/option/IOptionToken.sol";

///
library LibOptionToken {
    /////////

    // TODO generally robustify

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

    // TODO more thinking on European exercise, what this really means -- **no** early assignment risk for writers
    // TODO add Bermudan support

    function determineExerciseStyle(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOptionToken.ExerciseStyle exerciseStyle)
    {
        if (exerciseWindows[1] - exerciseWindows[0] <= 1 days) {
            exerciseStyle = IOptionToken.ExerciseStyle.EUROPEAN;
        } else {
            exerciseStyle = IOptionToken.ExerciseStyle.AMERICAN;
        }
    }

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
