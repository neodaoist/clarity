// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/option/IOptionToken.sol";

///
library LibOptionToken {
    /////////

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
