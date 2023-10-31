// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Library Under test
import {LibToken} from "../../src/library/LibToken.sol";

contract LibTokenTest is BaseClarityMarketsTest {
    /////////

    function test_paramsToHash() public {
        uint248 expectedHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint248 actualHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(USDCLIKE),
            americanExWeeklies[0],
            uint256(1750e18),
            IOptionToken.OptionType.CALL
        );

        assertEq(actualHash, expectedHash, "paramsToHash");
    }

    function test_hashToId() public {
        uint248 instrumentHash = uint248(bytes31(keccak256("setec astronomy")));
        uint256 expectedId = uint256(instrumentHash) << 8;
        uint256 actualId = LibToken.hashToId(instrumentHash);

        assertEq(actualId, expectedId, "hashToId");
    }

    function test_idToHash() public {
        uint256 tokenId = type(uint256).max / 2;
        uint248 expectedHash = uint248(tokenId >> 8);
        uint248 actualHash = LibToken.idToHash(tokenId);

        assertEq(actualHash, expectedHash, "idToHash");
    }

    function test_paramsToHash_hashToId_idToHash() public {
        uint248 expectedHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );

        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(USDCLIKE),
            americanExWeeklies[0],
            uint256(1750e18),
            IOptionToken.OptionType.CALL
        );
        uint256 tokenId = LibToken.hashToId(instrumentHash);
        uint248 actualHash = LibToken.idToHash(tokenId);

        assertEq(actualHash, expectedHash, "paramsToHash_hashToId_idToHash");
    }

    function test_longToShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 expectedShortId = longId | 1;
        uint256 actualShortId = LibToken.longToShort(longId);

        assertEq(actualShortId, expectedShortId, "longToShort");
    }

    function test_longToAssignedShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 expectedAssignedShortId = longId | 2;
        uint256 actualAssignedShortId = LibToken.longToAssignedShort(longId);

        assertEq(actualAssignedShortId, expectedAssignedShortId, "longToAssignedShort");
    }

    function test_shortToLong() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 shortId = LibToken.longToShort(longId);

        assertEq(LibToken.shortToLong(shortId), longId, "shortToLong");
    }

    function test_assignedShortToLong() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 assignedShortId = LibToken.longToAssignedShort(longId);

        assertEq(LibToken.assignedShortToLong(assignedShortId), longId, "assignedShortToLong");
    }

    function test_assignedShortToShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 shortId = LibToken.longToShort(longId);
        uint256 assignedShortId = LibToken.longToAssignedShort(longId);

        assertEq(LibToken.assignedShortToShort(assignedShortId), shortId, "assignedShortToShort");
    }

    function test_tokenType() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        americanExWeeklies[0],
                        uint256(1750e18),
                        IOptionToken.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 shortId = longId | 1;
        uint256 assignedShortId = longId | 2;

        assertEq(LibToken.tokenType(longId), IOptionToken.TokenType.LONG, "tokenType(longId)");
        assertEq(LibToken.tokenType(shortId), IOptionToken.TokenType.SHORT, "tokenType(shortId)");
        assertEq(
            LibToken.tokenType(assignedShortId),
            IOptionToken.TokenType.ASSIGNED_SHORT,
            "tokenType(assignedShortId)"
        );
    }

    function testRevert_tokenType_whenNotValid() public {
        uint256 malformedTokenId = type(uint256).max / 2;

        vm.expectRevert(stdError.enumConversionError);

        LibToken.tokenType(malformedTokenId);
    }
}
