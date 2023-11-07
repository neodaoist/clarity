// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library LibMetadata {
    /////////

    struct Json {
        string hey;
    }

    struct Svg {
        string ho;
    }

    string internal constant JSON1 = '{"name": "Clarity - ';
    string internal constant JSON_TEMP_TICKER = 'clr-WETH-FRAX-20OCT23-1750-C"';
    string internal constant JSON2 =
        ', "description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    // BASE64 ENCODED SVG HERE
    string internal constant JSON3 = '", "attributes": {"instrument_type": "';
    string internal constant JSON_TEMP_INSTRUMENT_TYPE = "Option";
    string internal constant JSON4 = '", "instrument_subtype": "';
    string internal constant JSON_TEMP_INSTRUMENT_SUBTYPE = "Call";
    string internal constant JSON5 = '", "token_type": "';
    string internal constant JSON_TEMP_TOKEN_TYPE = "Long";
    string internal constant JSON6 = '", "base_asset": "';
    string internal constant JSON_TEMP_BASE = "WETH";
    string internal constant JSON7 = '", "quote_asset": "';
    string internal constant JSON_TEMP_QUOTE = "FRAX";
    string internal constant JSON8 = '", "expiry": "';
    string internal constant JSON_TEMP_EXPIRY = "2023-10-20";
    string internal constant JSON9 = '", "exercise_style": "';
    string internal constant JSON_TEMP_STYLE = "American";
    string internal constant JSON10 = '", "strike_price": "';
    string internal constant JSON_TEMP_STRIKE = "1750";
    string internal constant JSON11 = '"}}';

    string internal constant SVG1 =
        '<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">';
    string internal constant SVG2 = "<style>";
    string internal constant SVG3 =
        ".primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }";
    string internal constant SVG4 =
        ".secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}";
    string internal constant SVG5 =
        ".tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }";
    string internal constant SVG6 = "</style>";
    string internal constant SVG7 = '<rect width="100%" height="100%" fill="#2b2b28" />';
    string internal constant SVG8 = "<g>";
    string internal constant SVG9 =
        unicode'<text x="20" y="68" class="primary">Clarity ––––––––––</text>';
    string internal constant SVG10 = '<text x="50" y="116" class="tertiary">';
    string internal constant SVG_TEMP_INSTRUMENT = "Long Call Option";
    string internal constant SVG11 =
        '</text><text x="50" y="164" class="secondary">Base asset: ';
    string internal constant SVG_TEMP_BASE = "WETH";
    string internal constant SVG12 =
        '</text><text x="50" y="200" class="secondary">Quote asset: ';
    string internal constant SVG_TEMP_QUOTE = "FRAX";
    string internal constant SVG13 =
        '</text><text x="50" y="236" class="secondary">Expiry: ';
    string internal constant SVG_TEMP_EXPIRY = "2023-10-20";
    string internal constant SVG14 =
        '</text><text x="50" y="272" class="secondary">Ex style: ';
    string internal constant SVG_TEMP_STYLE = "American";
    string internal constant SVG15 =
        '</text><text x="50" y="308" class="secondary">Strike price: ';
    string internal constant SVG_TEMP_STRIKE = "1750";
    string internal constant SVG16 = "</text></g>";
    string internal constant SVG17 = "</svg>";

    function json(
        string memory baseSymbol,
        string memory quoteSymbol,
        uint32 expiryTimestamp,
        string memory exerciseStyle,
        uint256 strikePrice
    ) public pure returns (string memory _json) {
        _json = string(
            abi.encodePacked(
                JSON1,
                JSON_TEMP_TICKER,
                JSON2,
                JSON_TEMP_INSTRUMENT_TYPE,
                svg(baseSymbol, quoteSymbol, expiryTimestamp, exerciseStyle, strikePrice),
                JSON3,
                JSON_TEMP_INSTRUMENT_SUBTYPE,
                JSON4,
                JSON_TEMP_TOKEN_TYPE,
                JSON5,
                JSON_TEMP_BASE,
                JSON6,
                JSON_TEMP_QUOTE,
                JSON7,
                JSON_TEMP_EXPIRY,
                JSON8,
                JSON_TEMP_STYLE,
                JSON9,
                JSON_TEMP_STRIKE,
                JSON10,
                JSON11
            )
        );
    }

    function svg(
        string memory baseSymbol,
        string memory quoteSymbol,
        uint32 expiryTimestamp,
        string memory exerciseStyle,
        uint256 strikePrice
    ) public pure returns (string memory _svg) {
        _svg = string(
            abi.encodePacked(
                SVG1,
                SVG2,
                SVG3,
                SVG4,
                SVG5,
                SVG6,
                SVG7,
                SVG8,
                SVG9,
                SVG10,
                SVG_TEMP_INSTRUMENT,
                SVG11,
                SVG_TEMP_BASE,
                SVG12,
                SVG_TEMP_QUOTE,
                SVG13,
                SVG_TEMP_EXPIRY,
                SVG14,
                SVG_TEMP_STYLE,
                SVG15,
                SVG_TEMP_STRIKE,
                SVG16,
                SVG17
            )
        );
    }

    ///////// WIP

    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

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

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function uint256ToString(uint256 _uint256) internal pure returns (string memory) {
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
                    mstore8(ptr, byte(mod(_uint256, 10), _SYMBOLS))
                }
                _uint256 /= 10;
                if (_uint256 == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
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
