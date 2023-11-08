// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOptionToken} from "../interface/option/IOptionToken.sol";

// Libraries
import {OptionErrors} from "../library/OptionErrors.sol";

library LibTime {
    /////////

    ///////// Exercise Style

    // TODO more thinking on European exercise, what this really means -- **no** early assignment risk for writers
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

    // TODO add unit test
    function toString(IOptionToken.ExerciseStyle exerciseStyle)
        internal
        pure
        returns (string memory str)
    {
        if (exerciseStyle == IOptionToken.ExerciseStyle.AMERICAN) {
            str = "American";
        } else if (exerciseStyle == IOptionToken.ExerciseStyle.EUROPEAN) {
            str = "European";
        } else {
            revert OptionErrors.InvalidExerciseStyle(); // unreachable
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
