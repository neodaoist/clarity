// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract MetadataTest is BaseClarityMarketsTest {
    /////////

    TextSnippets private textSnippets = TextSnippets({
        json1: '{"name": "Clarity - ',
        json2: '","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,',
        json3: '", "attributes": {"instrument_type": "',
        json4: '", "instrument_subtype": "',
        json5: '", "token_type": "',
        json6: '", "base_asset": "',
        json7: '", "quote_asset": "',
        json8: '", "expiry": "',
        json9: '", "exercise_style": "',
        json10: '", "strike_price": "',
        json11: '"}}',
        svg1: '<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g>',
        svg2: unicode'<text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">',
        svg3: '</text><text x="50" y="164" class="secondary">Base asset: ',
        svg4: '</text><text x="50" y="200" class="secondary">Quote asset: ',
        svg5: '</text><text x="50" y="236" class="secondary">Expiry: ',
        svg6: '</text><text x="50" y="272" class="secondary">Exercise style: ',
        svg7: '</text><text x="50" y="308" class="secondary">Strike price: ',
        svg8: "</text></g></svg>",
        blank: " "
    });

    struct TextSnippets {
        string json1;
        string json2;
        string json3;
        string json4;
        string json5;
        string json6;
        string json7;
        string json8;
        string json9;
        string json10;
        string json11;
        string svg1;
        string svg2;
        string svg3;
        string svg4;
        string svg5;
        string svg6;
        string svg7;
        string svg8;
        string blank;
    }

    function test_tokenURI() public {
        string memory tokenURI = clarity.tokenURI(1);

        console2.log(tokenURI);
    }
}
