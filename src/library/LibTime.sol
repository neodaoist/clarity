// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";

// Libraries
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";

library LibTime {
    /////////

    ///////// Exercise Style

    // TODO more thinking on European exercise, what this really means -- **no** early assignment risk for writers
    // TODO add Bermudan support

    function determineExerciseStyle(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOption.ExerciseStyle exerciseStyle)
    {
        if (exerciseWindows[1] - exerciseWindows[0] <= 1 hours) {
            exerciseStyle = IOption.ExerciseStyle.EUROPEAN;
        } else {
            exerciseStyle = IOption.ExerciseStyle.AMERICAN;
        }
    }

    ///////// Exercise Window

    function toExerciseWindow(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOption.ExerciseWindow memory timePair)
    {
        // timePairs = new IOption.ExerciseWindow[](exerciseWindows.length / 2);

        // for (uint256 i = 0; i < exerciseWindows.length; i += 2) {
        //     timePairs[i / 2] = IOption.ExerciseWindow(exerciseWindows[i], exerciseWindows[i + 1]);
        // }

        timePair = IOption.ExerciseWindow(exerciseWindows[0], exerciseWindows[1]);
    }

    function fromExerciseWindow(IOption.ExerciseWindow calldata timePair)
        external
        pure
        returns (uint32[] memory exerciseWindows)
    {}
}
