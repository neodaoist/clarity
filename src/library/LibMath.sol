// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Libraries
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

library LibMath {
    /////////

    using SafeCastLib for uint256;

    /////////

    uint8 internal constant CONTRACT_SCALAR = 6;

    ///////// Clearing Unit Conversion

    function oneClearingUnit(uint8 baseAssetDecimals)
        internal
        pure
        returns (uint64 unit)
    {
        unit = (10 ** (baseAssetDecimals - CONTRACT_SCALAR)).safeCastTo64();
    }

    ///////// Strike Price Conversions

    function actualScaledDownToClearingStrikeUnit(uint256 strike)
        internal
        pure
        returns (uint64 scaled)
    {
        scaled = (strike / (10 ** CONTRACT_SCALAR)).safeCastTo64();
    }

    function clearingScaledUpToActualStrike(uint64 strike)
        internal
        pure
        returns (uint256 scaled)
    {
        scaled = strike * (10 ** CONTRACT_SCALAR);
    }

    function actualScaledDownToHumanReadableStrike(
        uint256 strike,
        uint8 quoteAssetDecimals
    ) internal pure returns (uint64 scaled) {
        scaled = (strike / (10 ** quoteAssetDecimals)).safeCastTo64();
    }

    function clearingScaledDownToHumanReadableStrike(
        uint64 strike,
        uint8 quoteAssetDecimals
    ) internal pure returns (uint64 scaled) {
        scaled = (strike / (10 ** (quoteAssetDecimals - CONTRACT_SCALAR))).safeCastTo64();
    }
}
