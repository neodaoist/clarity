// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTest.t.sol";

// Library Under test
import {LibPosition} from "../../src/library/LibPosition.sol";

contract LibPositionTest is BaseUnitTest {
    /////////

    ///////// Token ID Encoding

    function test_hashToId() public {
        uint248 instrumentHash = uint248(bytes31(keccak256("setec astronomy")));
        uint256 expectedId = uint256(instrumentHash) << 8;
        uint256 actualId = LibPosition.hashToId(instrumentHash);

        assertEq(actualId, expectedId, "hashToId");
    }

    function test_idToHash() public {
        uint256 tokenId = type(uint256).max / 2;
        uint248 expectedHash = uint248(tokenId >> 8);
        uint248 actualHash = LibPosition.idToHash(tokenId);

        assertEq(actualHash, expectedHash, "idToHash");
    }

    function testE2E_paramsToHash_hashToId_idToHash() public {
        uint248 expectedHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL,
                        IOption.ExerciseStyle.AMERICAN
                    )
                )
            )
        );

        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(USDCLIKE),
            FRI1,
            uint256(1750e18),
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );
        uint256 tokenId = LibPosition.hashToId(instrumentHash);
        uint248 actualHash = LibPosition.idToHash(tokenId);

        assertEq(actualHash, expectedHash, "paramsToHash_hashToId_idToHash");
    }

    function test_longToShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 expectedShortId = longId | 1;
        uint256 actualShortId = LibPosition.longToShort(longId);

        assertEq(actualShortId, expectedShortId, "longToShort");
    }

    function test_longToAssignedShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 expectedAssignedShortId = longId | 2;
        uint256 actualAssignedShortId = LibPosition.longToAssignedShort(longId);

        assertEq(actualAssignedShortId, expectedAssignedShortId, "longToAssignedShort");
    }

    function test_shortToLong() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 shortId = LibPosition.longToShort(longId);

        assertEq(LibPosition.shortToLong(shortId), longId, "shortToLong");
    }

    function test_shortToAssignedShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 shortId = LibPosition.longToShort(longId);
        uint256 assignedShortId = LibPosition.longToAssignedShort(longId);

        assertEq(
            LibPosition.shortToAssignedShort(shortId),
            assignedShortId,
            "shortToAssignedShort"
        );
    }

    function test_assignedShortToLong() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 assignedShortId = LibPosition.longToAssignedShort(longId);

        assertEq(
            LibPosition.assignedShortToLong(assignedShortId),
            longId,
            "assignedShortToLong"
        );
    }

    function test_assignedShortToShort() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 shortId = LibPosition.longToShort(longId);
        uint256 assignedShortId = LibPosition.longToAssignedShort(longId);

        assertEq(
            LibPosition.assignedShortToShort(assignedShortId),
            shortId,
            "assignedShortToShort"
        );
    }

    ///////// Token Type

    function test_tokenType() public {
        uint248 instrumentHash = uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        address(WETHLIKE),
                        address(USDCLIKE),
                        FRI1,
                        uint256(1750e18),
                        IOption.OptionType.CALL
                    )
                )
            )
        );
        uint256 longId = LibPosition.hashToId(instrumentHash);
        uint256 shortId = longId | 1;
        uint256 assignedShortId = longId | 2;

        assertEq(
            LibPosition.tokenType(longId), IPosition.TokenType.LONG, "tokenType(longId)"
        );
        assertEq(
            LibPosition.tokenType(shortId),
            IPosition.TokenType.SHORT,
            "tokenType(shortId)"
        );
        assertEq(
            LibPosition.tokenType(assignedShortId),
            IPosition.TokenType.ASSIGNED_SHORT,
            "tokenType(assignedShortId)"
        );
    }

    function test_tokenType_toString() public {
        assertEq(LibPosition.toString(IPosition.TokenType.LONG), "Long", "toString(LONG)");
        assertEq(
            LibPosition.toString(IPosition.TokenType.SHORT), "Short", "toString(SHORT)"
        );
        assertEq(
            LibPosition.toString(IPosition.TokenType.ASSIGNED_SHORT),
            "Assigned",
            "toString(ASSIGNED_SHORT)"
        );
    }

    function testRevert_tokenType_whenNotValid() public {
        uint256 malformedTokenId = type(uint256).max / 2;

        vm.expectRevert(stdError.enumConversionError);

        LibPosition.tokenType(malformedTokenId);
    }
}
