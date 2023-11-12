// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IPosition} from "../interface/IPosition.sol";
import {IOption} from "../interface/option/IOption.sol";

// Libraries
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";

library LibMetadata {
    /////////

    struct TokenUriParameters {
        string ticker;
        string instrumentSubtype;
        string tokenType;
        string baseAssetSymbol;
        string quoteAssetSymbol;
        string expiry;
        string exerciseStyle;
        string strikePrice;
    }

    ///////// Ticker

    // NOTE once we implement dMMyy date formatting, we can fit a nice ticker inside one word
    // eg, sfrxETH-sFRAX-10OCT23-A-170050-C

    function paramsToTicker(
        string memory baseAssetSymbol,
        string memory quoteAssetSymbol,
        string memory expiry,
        IOption.ExerciseStyle exerciseStyle,
        string memory strikePrice,
        IOption.OptionType optionType
    ) internal pure returns (string memory ticker) {
        ticker = string.concat(
            baseAssetSymbol,
            "-",
            quoteAssetSymbol,
            "-",
            expiry,
            "-",
            (exerciseStyle == IOption.ExerciseStyle.AMERICAN) ? "A" : "E",
            "-",
            strikePrice,
            "-",
            (optionType == IOption.OptionType.CALL ? "C" : "P")
        );
    }

    function tickerToFullTicker(string memory ticker, string memory tokenType)
        internal
        pure
        returns (string memory symbol)
    {
        symbol = string.concat("clr-", ticker, "-", tokenType);
    }

    ///////// Token URI

    function tokenURI(TokenUriParameters memory parameters)
        internal
        pure
        returns (string memory uri)
    {
        uri = string.concat(
            "data:application/json;base64,",
            base64Encode(
                bytes(
                    string.concat(
                        '{"name": "Clarity - ',
                        tickerToFullTicker(parameters.ticker, parameters.tokenType),
                        '","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,',
                        base64Encode(bytes(_svg(parameters))),
                        _jsonGeneralAttributes(parameters),
                        _jsonInstrumentAttributes(parameters),
                        '"}}'
                    )
                )
            )
        );
    }

    function _jsonGeneralAttributes(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory attributes)
    {
        attributes = string.concat(
            '", "attributes": {"instrument_type": "',
            "Option", // TODO
            '", "instrument_subtype": "',
            parameters.instrumentSubtype,
            '", "token_type": "',
            parameters.tokenType,
            '", "base_asset": "'
        );
    }

    function _jsonInstrumentAttributes(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory attributes)
    {
        attributes = string.concat(
            parameters.baseAssetSymbol,
            '", "quote_asset": "',
            parameters.quoteAssetSymbol,
            '", "expiry": "',
            parameters.expiry, // TODO
            '", "exercise_style": "',
            parameters.exerciseStyle,
            '", "strike_price": "',
            parameters.strikePrice
        );
    }

    function _svg(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory svg)
    {
        svg = string.concat(
            '<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g>',
            unicode'<text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">',
            _svgCompoundInstrumentName(parameters),
            _svgAssetInformation(parameters),
            _svgExerciseInformation(parameters),
            "</text></g></svg>"
        );
    }

    function _svgCompoundInstrumentName(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory name)
    {
        name = string.concat(
            parameters.tokenType,
            " ",
            parameters.instrumentSubtype,
            " ",
            "Option", // TODO
            " "
        );
    }

    function _svgAssetInformation(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory svg)
    {
        svg = string.concat(
            '</text><text x="50" y="164" class="secondary">Base asset: ',
            parameters.baseAssetSymbol,
            '</text><text x="50" y="200" class="secondary">Quote asset: ',
            parameters.quoteAssetSymbol,
            '</text><text x="50" y="236" class="secondary">Expiry: '
        );
    }

    function _svgExerciseInformation(TokenUriParameters memory parameters)
        private
        pure
        returns (string memory svg)
    {
        svg = string.concat(
            parameters.expiry, // TODO
            '</text><text x="50" y="272" class="secondary">Exercise style: ',
            parameters.exerciseStyle,
            '</text><text x="50" y="308" class="secondary">Strike price: ',
            parameters.strikePrice
        );
    }

    ///////// TODO Potentially Move Out

    function toBytes31(string memory str) internal pure returns (bytes31 _bytes31) {
        _bytes31 = bytes31(bytes(str));
    }

    function toString(bytes31 _bytes31) internal pure returns (string memory str) {
        uint8 i = 0;
        while (i < 31 && _bytes31[i] != 0) {
            i++;
        }

        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 31 && _bytes31[i] != 0; i++) {
            bytesArray[i] = _bytes31[i];
        }

        str = string(bytesArray);
    }

    ///////// Base 64 Encoding

    bytes private constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // TODO fix natspec, add OZ credit, etc.

    // [MIT License]
    // @author Brecht Devos <brecht@loopring.org>
    // @notice Encodes some bytes to the base64 representation
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out :=
                    add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
