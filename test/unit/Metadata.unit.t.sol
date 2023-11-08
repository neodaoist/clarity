// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract MetadataTest is BaseClarityMarketsTest {
    /////////

    using LibToken for uint256;

    string private constant BASE64 = "data:application/json;base64,";

    // Initial - clr_WETH_USDC_27OCT23_1950
    // Long Call
    string private constant JSONPRE_clr_WETH_USDC_27OCT23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant SVG_clr_WETH_USDC_27OCT23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant JSONPOST_clr_WETH_USDC_27OCT23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Put
    string private constant JSONPRE_clr_WETH_USDC_27OCT23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant SVG_clr_WETH_USDC_27OCT23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant JSONPOST_clr_WETH_USDC_27OCT23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';

    /////////

    // Different token types - Shorts and Assigned Shorts
    // Short Call
    string private constant TOKEN_TYPE_SHORT_JSONPRE_clr_WETH_USDC_27OCT23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant TOKEN_TYPE_SHORT_SVG_clr_WETH_USDC_27OCT23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Short Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant TOKEN_TYPE_SHORT_JSONPOST_clr_WETH_USDC_27OCT23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Short", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';
    // Short Put
    string private constant TOKEN_TYPE_SHORT_JSONPRE_clr_WETH_USDC_27OCT23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant TOKEN_TYPE_SHORT_SVG_clr_WETH_USDC_27OCT23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Short Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant TOKEN_TYPE_SHORT_JSONPOST_clr_WETH_USDC_27OCT23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Short", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';
    // Assigned Short Call
    string private constant TOKEN_TYPE_ASSIGNED_JSONPRE_clr_WETH_USDC_27OCT23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant TOKEN_TYPE_ASSIGNED_SVG_clr_WETH_USDC_27OCT23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Assigned Short Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant TOKEN_TYPE_ASSIGNED_JSONPOST_clr_WETH_USDC_27OCT23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Assigned Short", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';
    // Assigned Short Put
    string private constant TOKEN_TYPE_ASSIGNED_JSONPRE_clr_WETH_USDC_27OCT23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant TOKEN_TYPE_ASSIGNED_SVG_clr_WETH_USDC_27OCT23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Assigned Short Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant TOKEN_TYPE_ASSIGNED_JSONPOST_clr_WETH_USDC_27OCT23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Assigned Short", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "1700"}}';

    // Different expiries - 3NOV23 (1698998400), 8NOV23 (1699434000), and 20APR24 (1713600000)
    // Long Call
    string private constant EXPIRY1_JSONPRE_clr_WETH_USDC_3NOV23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY1_SVG_clr_WETH_USDC_3NOV23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698998400</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY1_JSONPOST_clr_WETH_USDC_3NOV23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698998400", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Put
    string private constant EXPIRY1_JSONPRE_clr_WETH_USDC_3NOV23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY1_SVG_clr_WETH_USDC_3NOV23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698998400</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY1_JSONPOST_clr_WETH_USDC_3NOV23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698998400", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Call
    string private constant EXPIRY2_JSONPRE_clr_WETH_USDC_8NOV23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY2_SVG_clr_WETH_USDC_8NOV23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1699434000</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY2_JSONPOST_clr_WETH_USDC_8NOV23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1699434000", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Put
    string private constant EXPIRY2_JSONPRE_clr_WETH_USDC_8NOV23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY2_SVG_clr_WETH_USDC_8NOV23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1699434000</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY2_JSONPOST_clr_WETH_USDC_8NOV23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1699434000", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Call
    string private constant EXPIRY3_JSONPRE_clr_WETH_USDC_20APR24_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY3_SVG_clr_WETH_USDC_20APR24_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1713600000</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY3_JSONPOST_clr_WETH_USDC_20APR24_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1713600000", "exercise_style": "American", "strike_price": "1700"}}';
    // Long Put
    string private constant EXPIRY3_JSONPRE_clr_WETH_USDC_20APR24_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EXPIRY3_SVG_clr_WETH_USDC_20APR24_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1713600000</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EXPIRY3_JSONPOST_clr_WETH_USDC_20APR24_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1713600000", "exercise_style": "American", "strike_price": "1700"}}';

    // Different exercise style - European
    // Long Call
    string private constant EX_STYLE_EURO_JSONPRE_clr_WETH_USDC_27OCT23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EX_STYLE_EURO_SVG_clr_WETH_USDC_27OCT23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: European</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EX_STYLE_EURO_JSONPOST_clr_WETH_USDC_27OCT23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "European", "strike_price": "1700"}}';
    // Long Put
    string private constant EX_STYLE_EURO_JSONPRE_clr_WETH_USDC_27OCT23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant EX_STYLE_EURO_SVG_clr_WETH_USDC_27OCT23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: USDCLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: European</text><text x="50" y="308" class="secondary">Strike price: 1700</text></g></svg>';
    string private constant EX_STYLE_EURO_JSONPOST_clr_WETH_USDC_27OCT23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "USDCLIKE", "expiry": "1698393600", "exercise_style": "European", "strike_price": "1700"}}';

    // Different strike - 2022
    // Long Call
    string private constant STRIKE_JSONPRE_clr_WETH_LUSD_27OCT23_2022_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant STRIKE_SVG_clr_WETH_LUSD_27OCT23_2022_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: LUSDLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 2022</text></g></svg>';
    string private constant STRIKE_JSONPOST_clr_WETH_LUSD_27OCT23_2022_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "LUSDLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "2022"}}';
    // Long Put
    string private constant STRIKE_JSONPRE_clr_WETH_LUSD_27OCT23_2022_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant STRIKE_SVG_clr_WETH_LUSD_27OCT23_2022_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WETHLIKE</text><text x="50" y="200" class="secondary">Quote asset: LUSDLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 2022</text></g></svg>';
    string private constant STRIKE_JSONPOST_clr_WETH_LUSD_27OCT23_2022_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WETHLIKE", "quote_asset": "LUSDLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "2022"}}';

    // Different assets - WBTC and FRAX
    string private constant ASSETS_JSONPRE_clr_WBTC_FRAX_27OCT23_1950_C =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-C","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant ASSETS_SVG_clr_WBTC_FRAX_27OCT23_1950_C =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Call Option </text><text x="50" y="164" class="secondary">Base asset: WBTCLIKE</text><text x="50" y="200" class="secondary">Quote asset: FRAXLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 35000</text></g></svg>';
    string private constant ASSETS_JSONPOST_clr_WBTC_FRAX_27OCT23_1950_C =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Call", "token_type": "Long", "base_asset": "WBTCLIKE", "quote_asset": "FRAXLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "35000"}}';

    string private constant ASSETS_JSONPRE_clr_WBTC_FRAX_27OCT23_1950_P =
        '{"name": "Clarity - clr-WETH-FRAX-20OCT23-1750-P","description": "Clarity is a decentralized counterparty clearinghouse (DCP), for the writing, transfer, and settlement of options and futures contracts on the EVM.", "image": "data:image/svg+xml;base64,';
    string private constant ASSETS_SVG_clr_WBTC_FRAX_27OCT23_1950_P =
        unicode'<svg width="350px" height="350px" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.primary { fill: #64e380; font-family: sans-serif; font-size: 36px; }.secondary { fill: #64e380; font-family: sans-serif; font-size: 24px;}.tertiary { fill: #64e380; font-family: sans-serif; font-size: 18px; font-style: italic }</style><rect width="100%" height="100%" fill="#2b2b28" /><g><text x="20" y="68" class="primary">Clarity ––––––––––</text><text x="50" y="116" class="tertiary">Long Put Option </text><text x="50" y="164" class="secondary">Base asset: WBTCLIKE</text><text x="50" y="200" class="secondary">Quote asset: FRAXLIKE</text><text x="50" y="236" class="secondary">Expiry: 1698393600</text><text x="50" y="272" class="secondary">Exercise style: American</text><text x="50" y="308" class="secondary">Strike price: 35000</text></g></svg>';
    string private constant ASSETS_JSONPOST_clr_WBTC_FRAX_27OCT23_1950_P =
        '", "attributes": {"instrument_type": "Option", "instrument_subtype": "Put", "token_type": "Long", "base_asset": "WBTCLIKE", "quote_asset": "FRAXLIKE", "expiry": "1698393600", "exercise_style": "American", "strike_price": "35000"}}';

    /////////

    function test_tokenURI_long() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId);
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                JSONPRE_clr_WETH_USDC_27OCT23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(SVG_clr_WETH_USDC_27OCT23_1950_C)
                                ),
                                JSONPOST_clr_WETH_USDC_27OCT23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI initial long call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken);
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                JSONPRE_clr_WETH_USDC_27OCT23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(SVG_clr_WETH_USDC_27OCT23_1950_P)
                                ),
                                JSONPOST_clr_WETH_USDC_27OCT23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI initial long put");
    }

    function test_tokenURI_short() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId.longToShort());
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                TOKEN_TYPE_SHORT_JSONPRE_clr_WETH_USDC_27OCT23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(
                                        TOKEN_TYPE_SHORT_SVG_clr_WETH_USDC_27OCT23_1950_C
                                    )
                                ),
                                TOKEN_TYPE_SHORT_JSONPOST_clr_WETH_USDC_27OCT23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI initial short call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken.longToShort());
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                TOKEN_TYPE_SHORT_JSONPRE_clr_WETH_USDC_27OCT23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(
                                        TOKEN_TYPE_SHORT_SVG_clr_WETH_USDC_27OCT23_1950_P
                                    )
                                ),
                                TOKEN_TYPE_SHORT_JSONPOST_clr_WETH_USDC_27OCT23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI initial short put");
    }

    function test_tokenURI_assignedShort() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI =
            clarity.tokenURI(callOptionTokenId.longToAssignedShort());
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                TOKEN_TYPE_ASSIGNED_JSONPRE_clr_WETH_USDC_27OCT23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(
                                        TOKEN_TYPE_ASSIGNED_SVG_clr_WETH_USDC_27OCT23_1950_C
                                    )
                                ),
                                TOKEN_TYPE_ASSIGNED_JSONPOST_clr_WETH_USDC_27OCT23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI initial assigned short call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken.longToAssignedShort());
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                TOKEN_TYPE_ASSIGNED_JSONPRE_clr_WETH_USDC_27OCT23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(
                                        TOKEN_TYPE_ASSIGNED_SVG_clr_WETH_USDC_27OCT23_1950_P
                                    )
                                ),
                                TOKEN_TYPE_ASSIGNED_JSONPOST_clr_WETH_USDC_27OCT23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI initial assigned short put");
    }

    function test_tokenURI_differentExpiry1() public {
        // 3NOV23 (1698998400)
        uint32[] memory exWindow1 = new uint32[](2);
        exWindow1[0] = FRI1;
        exWindow1[1] = 1698998400;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow1,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId);
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY1_JSONPRE_clr_WETH_USDC_3NOV23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY1_SVG_clr_WETH_USDC_3NOV23_1950_C)
                                ),
                                EXPIRY1_JSONPOST_clr_WETH_USDC_3NOV23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI different expiry 1 call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionTokenId = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow1,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionTokenId);
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY1_JSONPRE_clr_WETH_USDC_3NOV23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY1_SVG_clr_WETH_USDC_3NOV23_1950_P)
                                ),
                                EXPIRY1_JSONPOST_clr_WETH_USDC_3NOV23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI different expiry 1 put");
    }

    function test_tokenURI_differentExpiry2() public {
        // 8NOV23 (1699434000)
        uint32[] memory exWindow2 = new uint32[](2);
        exWindow2[0] = FRI1;
        exWindow2[1] = 1699434000;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId2 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow2,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI2 = clarity.tokenURI(callOptionTokenId2);
        string memory expectedCall2 = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY2_JSONPRE_clr_WETH_USDC_8NOV23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY2_SVG_clr_WETH_USDC_8NOV23_1950_C)
                                ),
                                EXPIRY2_JSONPOST_clr_WETH_USDC_8NOV23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI2);
        assertEq(callTokenURI2, expectedCall2, "tokenURI different expiry 2 call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionTokenId2 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow2,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI2 = clarity.tokenURI(putOptionTokenId2);
        string memory expectedPut2 = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY2_JSONPRE_clr_WETH_USDC_8NOV23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY2_SVG_clr_WETH_USDC_8NOV23_1950_P)
                                ),
                                EXPIRY2_JSONPOST_clr_WETH_USDC_8NOV23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI2);
        assertEq(putTokenURI2, expectedPut2, "tokenURI different expiry 2 put");
    }

    function test_tokenURI_differentExpiry3() public {
        // 20APR24 (1713600000)
        uint32[] memory exWindow3 = new uint32[](2);
        exWindow3[0] = FRI1;
        exWindow3[1] = 1713600000;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId3 = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow3,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI3 = clarity.tokenURI(callOptionTokenId3);
        string memory expectedCall3 = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY3_JSONPRE_clr_WETH_USDC_20APR24_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY3_SVG_clr_WETH_USDC_20APR24_1950_C)
                                ),
                                EXPIRY3_JSONPOST_clr_WETH_USDC_20APR24_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI3, expectedCall3, "tokenURI different expiry 3 call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionTokenId3 = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: exWindow3,
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI3 = clarity.tokenURI(putOptionTokenId3);
        string memory expectedPut3 = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EXPIRY3_JSONPRE_clr_WETH_USDC_20APR24_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(EXPIRY3_SVG_clr_WETH_USDC_20APR24_1950_P)
                                ),
                                EXPIRY3_JSONPOST_clr_WETH_USDC_20APR24_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI3, expectedPut3, "tokenURI different expiry 3 put");
    }

    function test_tokenURI_differentExerciseStyle() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: europeanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId);
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EX_STYLE_EURO_JSONPRE_clr_WETH_USDC_27OCT23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(EX_STYLE_EURO_SVG_clr_WETH_USDC_27OCT23_1950_C)
                                ),
                                EX_STYLE_EURO_JSONPOST_clr_WETH_USDC_27OCT23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI different exercise style call");

        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: europeanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken);
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                EX_STYLE_EURO_JSONPRE_clr_WETH_USDC_27OCT23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(EX_STYLE_EURO_SVG_clr_WETH_USDC_27OCT23_1950_P)
                                ),
                                EX_STYLE_EURO_JSONPOST_clr_WETH_USDC_27OCT23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI different exercise style put");
    }

    function test_tokenURI_differentStrike() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 2022e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId);
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                STRIKE_JSONPRE_clr_WETH_LUSD_27OCT23_2022_C,
                                LibMetadata.base64Encode(
                                    bytes(STRIKE_SVG_clr_WETH_LUSD_27OCT23_2022_C)
                                ),
                                STRIKE_JSONPOST_clr_WETH_LUSD_27OCT23_2022_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI different strike call");

        vm.startPrank(writer);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(LUSDLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 2022e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken);
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                STRIKE_JSONPRE_clr_WETH_LUSD_27OCT23_2022_P,
                                LibMetadata.base64Encode(
                                    bytes(STRIKE_SVG_clr_WETH_LUSD_27OCT23_2022_P)
                                ),
                                STRIKE_JSONPOST_clr_WETH_LUSD_27OCT23_2022_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI different strike put");
    }

    function test_tokenURI_differentAssets() public {
        vm.startPrank(writer);
        WBTCLIKE.approve(address(clarity), scaleUpAssetAmount(WBTCLIKE, STARTING_BALANCE));
        uint256 callOptionTokenId = clarity.writeCall({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 35_000e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory callTokenURI = clarity.tokenURI(callOptionTokenId);
        string memory expectedCall = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                ASSETS_JSONPRE_clr_WBTC_FRAX_27OCT23_1950_C,
                                LibMetadata.base64Encode(
                                    bytes(ASSETS_SVG_clr_WBTC_FRAX_27OCT23_1950_C)
                                ),
                                ASSETS_JSONPOST_clr_WBTC_FRAX_27OCT23_1950_C
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Call tokenURI", callTokenURI);
        assertEq(callTokenURI, expectedCall, "tokenURI different assets call");

        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
        uint256 putOptionToken = clarity.writePut({
            baseAsset: address(WBTCLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 35_000e18,
            optionAmount: 1e6
        });
        vm.stopPrank();

        string memory putTokenURI = clarity.tokenURI(putOptionToken);
        string memory expectedPut = string(
            abi.encodePacked(
                BASE64,
                LibMetadata.base64Encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                ASSETS_JSONPRE_clr_WBTC_FRAX_27OCT23_1950_P,
                                LibMetadata.base64Encode(
                                    bytes(ASSETS_SVG_clr_WBTC_FRAX_27OCT23_1950_P)
                                ),
                                ASSETS_JSONPOST_clr_WBTC_FRAX_27OCT23_1950_P
                            )
                        )
                    )
                )
            )
        );

        // console2.log("Put tokenURI", putTokenURI);
        assertEq(putTokenURI, expectedPut, "tokenURI different assets put");
    }

    ///////// TODO convert to private storage and get fancy reading from storage
    // https://book.getfoundry.sh/reference/forge-std/std-storage

    function test_assetStorage_whenCall() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        (bytes31 baseSymbol, uint8 baseDecimals) = clarity.assetStorage(address(WETHLIKE));
        assertEq(
            LibMetadata.bytes31ToString(baseSymbol),
            "WETHLIKE",
            "stored base asset symbol"
        );
        assertEq(baseDecimals, 18, "stored base asset decimals");

        (bytes31 quoteSymbol, uint8 quoteDecimals) =
            clarity.assetStorage(address(USDCLIKE));
        assertEq(
            LibMetadata.bytes31ToString(quoteSymbol),
            "USDCLIKE",
            "stored quote asset symbol"
        );
        assertEq(quoteDecimals, 6, "stored quote asset decimals");
    }

    function test_assetStorage_whenPut() public {
        vm.startPrank(writer);
        USDCLIKE.approve(address(clarity), scaleUpAssetAmount(USDCLIKE, STARTING_BALANCE));
        clarity.writePut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1700e6,
            optionAmount: 1e6
        });
        vm.stopPrank();

        (bytes31 baseSymbol, uint8 baseDecimals) = clarity.assetStorage(address(WETHLIKE));
        assertEq(
            LibMetadata.bytes31ToString(baseSymbol),
            "WETHLIKE",
            "stored base asset symbol"
        );
        assertEq(baseDecimals, 18, "stored base asset decimals");

        (bytes31 quoteSymbol, uint8 quoteDecimals) =
            clarity.assetStorage(address(USDCLIKE));
        assertEq(
            LibMetadata.bytes31ToString(quoteSymbol),
            "USDCLIKE",
            "stored quote asset symbol"
        );
        assertEq(quoteDecimals, 6, "stored quote asset decimals");
    }
}
