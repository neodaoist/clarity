// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTest.t.sol";

// Interfaces
import {IWrappedLongEvents} from "../../src/interface/adapter/IWrappedLongEvents.sol";

// Contracts
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";

// Contract Under Test
import {ClarityWrappedLong} from "../../src/adapter/ClarityWrappedLong.sol";

contract WrappedLongTest is BaseUnitTest {
    /////////

    using LibPosition for uint256;

    ClarityERC20Factory private factory;
    ClarityWrappedLong private wrappedLong;

    function setUp() public override {
        super.setUp();

        // deploy factory
        factory = new ClarityERC20Factory(clarity);
    }

    /////////
    // function wrapLongs(uint256 optionAmount) external;

    function test_wrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        // pre checks
        assertOptionBalances(
            clarity, writer, optionTokenId, 10e6, 10e6, 0, "writer before wrap"
        );
        assertOptionBalances(
            clarity, address(wrappedLong), optionTokenId, 0, 0, 0, "wrapper before wrap"
        );

        // When writer wraps 8 options
        vm.startPrank(writer);
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(
            clarity, writer, optionTokenId, 2e6, 10e6, 0, "writer after wrap"
        );
        assertOptionBalances(
            clarity, address(wrappedLong), optionTokenId, 8e6, 0, 0, "wrapper after wrap"
        );

        // check wrapper balance
        assertEq(wrappedLong.totalSupply(), 8e6, "wrapper totalSupply after wrap");
        assertEq(wrappedLong.balanceOf(writer), 8e6, "wrapper balance after wrap");
    }

    function test_wrapLongs_manyOptions() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        ClarityWrappedLong[] memory wrappedLongs = new ClarityWrappedLong[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(USDCLIKE),
                expiry: FRI1,
                strike: (1750 + i) * 10 ** 6,
                allowEarlyExercise: true,
                optionAmount: 10e6
            });
            wrappedLongs[i] =
                ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));

            // pre checks
            // check option balances
            assertOptionBalances(
                clarity, writer, optionTokenIds[i], 10e6, 10e6, 0, "writer before wrap"
            );
            assertOptionBalances(
                clarity,
                address(wrappedLongs[i]),
                optionTokenIds[i],
                0,
                0,
                0,
                "wrapper before wrap"
            );

            // When writer wraps options
            clarity.approve(
                address(wrappedLongs[i]), optionTokenIds[i], type(uint256).max
            );
            wrappedLongs[i].wrapLongs(uint64((10 - i) * 10 ** 6));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            assertOptionBalances(
                clarity,
                writer,
                optionTokenIds[i],
                i * 10 ** 6,
                10e6,
                0,
                "writer after wrap"
            );
            assertOptionBalances(
                clarity,
                address(wrappedLongs[i]),
                optionTokenIds[i],
                (10 - i) * 10 ** 6,
                0,
                0,
                "wrapper after wrap"
            );

            // check wrapper balances
            assertEq(
                wrappedLongs[i].totalSupply(),
                (10 - i) * 10 ** 6,
                "wrapper totalSupply after wrap"
            );
            assertEq(
                wrappedLongs[i].balanceOf(writer),
                (10 - i) * 10 ** 6,
                "wrapper balance after wrap"
            );
        }
    }

    // TODO test_wrapLongs_manyOptions_manyCallers

    // Events

    function testEvent_wrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IWrappedLongEvents.ClarityLongsWrapped(writer, optionTokenId, 8e6);

        // When
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_wrapLongs_whenAmountZero() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.expectRevert(IOptionErrors.WrapAmountZero.selector);

        vm.prank(writer);
        wrappedLong.wrapLongs(0);
    }

    function testRevert_wrapLongs_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.warp(FRI1 + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector,
                optionTokenId,
                uint32(block.timestamp)
            )
        );

        vm.prank(writer);
        wrappedLong.wrapLongs(10e6);
    }

    function testRevert_wrapLongs_whenCallerHoldsInsufficientLongs() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientLongBalance.selector, optionTokenId, 10e6
            )
        );

        vm.prank(writer);
        wrappedLong.wrapLongs(10.000001e6);
    }

    function testRevert_wrapLongs_whenCallerHasGrantedInsufficientClearinghouseApproval()
        public
    {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));

        // And insufficient Clearinghouse approval has been granted to Factory
        clarity.approve(address(wrappedLong), optionTokenId, 8e6 - 1);

        // Then
        vm.expectRevert(stdError.arithmeticError);

        // When
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();
    }

    /////////
    // function unwrapLongs(uint256 amount) external;

    function test_unwrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // pre checks
        // check option balances
        assertOptionBalances(
            clarity, writer, optionTokenId, 2e6, 10e6, 0, "writer before unwrap"
        );
        assertOptionBalances(
            clarity,
            address(wrappedLong),
            optionTokenId,
            8e6,
            0,
            0,
            "wrapper before unwrap"
        );

        // check wrapper balance
        assertEq(wrappedLong.totalSupply(), 8e6);
        assertEq(wrappedLong.balanceOf(writer), 8e6, "wrapper balance before unwrap");

        // When writer unwraps 5 options
        vm.prank(writer);
        wrappedLong.unwrapLongs(5e6);

        // Then
        // check option balances
        assertOptionBalances(
            clarity, writer, optionTokenId, 7e6, 10e6, 0, "writer after unwrap"
        );
        assertOptionBalances(
            clarity,
            address(wrappedLong),
            optionTokenId,
            3e6,
            0,
            0,
            "wrapper after unwrap"
        );

        // check wrapper balance
        assertEq(wrappedLong.totalSupply(), 3e6, "wrapper totalSupply after unwrap");
        assertEq(wrappedLong.balanceOf(writer), 3e6, "wrapper balance after unwrap");
    }

    function test_unwrapLongs_many() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        ClarityWrappedLong[] memory wrappedLongs = new ClarityWrappedLong[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(USDCLIKE),
                expiry: FRI1,
                strike: (1750 + i) * 10 ** 6,
                allowEarlyExercise: true,
                optionAmount: 10e6
            });
            wrappedLongs[i] =
                ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));
            clarity.approve(
                address(wrappedLongs[i]), optionTokenIds[i], type(uint256).max
            );
            wrappedLongs[i].wrapLongs(uint64((10 - i) * 10 ** 6));

            // pre checks
            // check option balances
            assertOptionBalances(
                clarity,
                writer,
                optionTokenIds[i],
                i * 10 ** 6,
                10e6,
                0,
                "writer before unwrap"
            );
            assertOptionBalances(
                clarity,
                address(wrappedLongs[i]),
                optionTokenIds[i],
                (10 - i) * 10 ** 6,
                0,
                0,
                "wrapper before unwrap"
            );

            // check wrapper balance
            assertEq(
                wrappedLongs[i].totalSupply(),
                (10 - i) * 10 ** 6,
                "wrapper totalSupply before unwrap"
            );
            assertEq(
                wrappedLongs[i].balanceOf(writer),
                (10 - i) * 10 ** 6,
                "wrapper balance before unwrap"
            );

            // When
            wrappedLongs[i].unwrapLongs(uint64(((10 - i) * 10 ** 6) - (i * 10 ** 5)));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            assertOptionBalances(
                clarity,
                writer,
                optionTokenIds[i],
                10e6 - (i * 10 ** 5),
                10e6,
                0,
                "writer after unwrap"
            );
            assertOptionBalances(
                clarity,
                address(wrappedLongs[i]),
                optionTokenIds[i],
                i * 10 ** 5,
                0,
                0,
                "wrapper after unwrap"
            );

            // check wrapper balance
            assertEq(
                wrappedLongs[i].totalSupply(),
                i * 10 ** 5,
                "wrapper totalSupply after unwrap"
            );
            assertEq(
                wrappedLongs[i].balanceOf(writer),
                i * 10 ** 5,
                "wrapper balance after unwrap"
            );
        }
    }

    // Events

    function testEvent_unwrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IWrappedLongEvents.ClarityLongsUnwrapped(writer, optionTokenId, 5.000001e6);

        // When
        wrappedLong.unwrapLongs(5.000001e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_unwrapLongs_whenAmountZero() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.UnwrapAmountZero.selector);

        // When
        vm.prank(writer);
        wrappedLong.unwrapLongs(0);
    }

    function testRevert_unwrapLongs_whenCallerHoldsInsufficientWrappedLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(USDCLIKE),
            expiry: FRI1,
            strike: 1750e6,
            allowEarlyExercise: true,
            optionAmount: 10e6
        });
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientWrappedBalance.selector, optionTokenId, 8e6
            )
        );

        // When
        vm.prank(writer);
        wrappedLong.unwrapLongs(8.000001e6);
    }

    /////////
    // function exerciseOptions(uint256 amount) external;

    // TODO
}
