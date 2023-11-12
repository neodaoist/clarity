// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";

library LibOption {
    /////////

    bytes16 private constant SYMBOLS = "0123456789abcdef";

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
            revert(); // theoretically unreachable
        }
    }

    ///////// Exercise Style

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
            revert(); // theoretically unreachable
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

    // function fromExerciseWindow(IOption.ExerciseWindow calldata exerciseWindow)
    //     external
    //     pure
    //     returns (uint32[] memory exerciseWindows)
    // {}

    ///////// String Conversion for Strike Price and Unix Timestamp

    // TODO add attribution

    function toString(uint256 _uint256) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(_uint256) + 1;
            string memory buffer = new string(length);
            uint256 ptr;

            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }

            while (true) {
                ptr--;

                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(_uint256, 10), SYMBOLS))
                }

                _uint256 /= 10;
                if (_uint256 == 0) break;
            }

            return buffer;
        }
    }

    function log10(uint256 value) private pure returns (uint256) {
        uint256 result = 0;

        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }

        return result;
    }
}
