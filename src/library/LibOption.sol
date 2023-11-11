// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";

library LibOption {
    /////////

    ///////// Instrument Hash

    function paramsToHash(
        address baseAsset,
        address quoteAsset,
        uint32[] memory exerciseWindow,
        uint256 strikePrice,
        IOption.OptionType optionType
    ) internal pure returns (uint248 hash) {
        hash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        baseAsset, quoteAsset, exerciseWindow, strikePrice, optionType
                    )
                )
            )
        );
    }

    ///////// Option Type

    // TODO write unit test
    function toString(IOption.OptionType optionType)
        internal
        pure
        returns (string memory str)
    {
        if (optionType == IOption.OptionType.CALL) {
            str = "Call";
        } else if (optionType == IOption.OptionType.PUT) {
            str = "Put";
        } else {
            revert IOptionErrors.InvalidInstrumentSubtype(); // unreachable
        }
    }

    ///////// Exercise Style

    // TODO more thinking on European exercise, what this really means -- **no** early assignment risk for writers

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

    // TODO add unit test
    function toString(IOption.ExerciseStyle exerciseStyle)
        internal
        pure
        returns (string memory str)
    {
        if (exerciseStyle == IOption.ExerciseStyle.AMERICAN) {
            str = "American";
        } else if (exerciseStyle == IOption.ExerciseStyle.EUROPEAN) {
            str = "European";
        } else {
            revert IOptionErrors.InvalidExerciseStyle(); // unreachable
        }
    }

    ///////// Exercise Window

    function toExerciseWindow(uint32[] calldata exerciseWindows)
        external
        pure
        returns (IOption.ExerciseWindow memory exerciseWindow)
    {
        exerciseWindow = IOption.ExerciseWindow(exerciseWindows[0], exerciseWindows[1]);
    }

    function fromExerciseWindow(IOption.ExerciseWindow calldata exerciseWindow)
        external
        pure
        returns (uint32[] memory exerciseWindows)
    {}
}
