// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

// Interfaces
import {IWrappedShortEvents} from "../../src/interface/adapter/IWrappedShortEvents.sol";

// Contracts
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";

// Contract Under Test
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

contract WrappedShortTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;

    ClarityERC20Factory private factory;
    ClarityWrappedShort private wrappedShort;

    function setUp() public override {
        super.setUp();

        // deploy factory
        factory = new ClarityERC20Factory(clarity);
    }

    /////////
    // function wrapShorts(uint256 optionAmount) external;

    function test_wrapShorts() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 10e6, 10e6, 0, "before wrap");
        assertOptionBalances(
            address(wrappedShort), optionTokenId, 0, 0, 0, "wrapper before wrap"
        );

        // When writer wraps 8 options
        vm.startPrank(writer);
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(writer, optionTokenId, 10e6, 2e6, 0, "writer after wrap");
        assertOptionBalances(
            address(wrappedShort), optionTokenId, 0, 8e6, 0, "wrapper after wrap"
        );

        // check wrapper balance
        assertEq(wrappedShort.totalSupply(), 8e6, "wrapper totalSupply after wrap");
        assertEq(wrappedShort.balanceOf(writer), 8e6, "wrapper balance after wrap");
    }

    function test_wrapShorts_manyOptions() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        uint256[] memory shortTokenIds = new uint256[](numOptions);
        ClarityWrappedShort[] memory wrappedShorts = new ClarityWrappedShort[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeNewCall(
                address(WETHLIKE),
                address(FRAXLIKE),
                FRI1,
                (1750 + i) * 10 ** 18,
                true,
                10e6
            );
            shortTokenIds[i] = optionTokenIds[i].longToShort();
            wrappedShorts[i] =
                ClarityWrappedShort(factory.deployWrappedShort(shortTokenIds[i]));

            // pre checks
            // check option balances
            assertOptionBalances(
                writer, optionTokenIds[i], 10e6, 10e6, 0, "writer before wrap"
            );
            assertOptionBalances(
                address(wrappedShorts[i]),
                optionTokenIds[i],
                0,
                0,
                0,
                "wrapper before wrap"
            );

            // When writer wraps shorts
            clarity.approve(
                address(wrappedShorts[i]), shortTokenIds[i], type(uint256).max
            );
            wrappedShorts[i].wrapShorts(uint64((10 - i) * 10 ** 6));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            assertOptionBalances(
                writer, optionTokenIds[i], 10e6, i * 10 ** 6, 0, "writer after wrap"
            );
            assertOptionBalances(
                address(wrappedShorts[i]),
                optionTokenIds[i],
                0,
                (10 - i) * 10 ** 6,
                0,
                "wrapper after wrap"
            );

            // check wrapper balances
            assertEq(
                wrappedShorts[i].totalSupply(),
                (10 - i) * 10 ** 6,
                "wrapper totalSupply after wrap"
            );
            assertEq(
                wrappedShorts[i].balanceOf(writer),
                (10 - i) * 10 ** 6,
                "wrapper balance after wrap"
            );
        }
    }

    // TODO test_wrapShorts_manyOptions_manyCallers

    // Events

    function testEvent_wrapShorts() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IWrappedShortEvents.ClarityShortsWrapped(writer, shortTokenId, 8e6);

        // When
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_wrapShorts_whenAmountZero() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        vm.stopPrank();

        vm.expectRevert(IOptionErrors.WrapAmountZero.selector);

        vm.prank(writer);
        wrappedShort.wrapShorts(0);
    }

    function testRevert_wrapShorts_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
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
        wrappedShort.wrapShorts(10e6);
    }

    function testRevert_wrapShorts_whenShortHasBeenAssigned() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);

        // And the option has been exercised (ie, the short has been assigned)
        vm.warp(FRI1 - 1 seconds);
        FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(optionTokenId, 1);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.CanOnlyTransferShortIfUnassigned.selector);

        // When
        vm.prank(writer);
        wrappedShort.wrapShorts(10e6 - 1);
    }

    function testRevert_wrapShorts_whenCallerHoldsInsufficientShorts() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientShortBalance.selector, shortTokenId, 10e6
            )
        );

        vm.prank(writer);
        wrappedShort.wrapShorts(10.000001e6);
    }

    function testRevert_wrapShorts_whenCallerHasGrantedInsufficientClearinghouseApproval()
        public
    {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));

        // And insufficient Clearinghouse approval has been granted to Factory
        clarity.approve(address(wrappedShort), shortTokenId, 8e6 - 1);

        // Then
        vm.expectRevert(stdError.arithmeticError);

        // When
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();
    }

    /////////
    // function unwrapShorts(uint256 amount) external;

    function test_unwrapShorts() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();

        // pre checks
        // check option balances
        assertOptionBalances(writer, optionTokenId, 10e6, 2e6, 0, "writer before unwrap");
        assertOptionBalances(
            address(wrappedShort), optionTokenId, 0, 8e6, 0, "wrapper before unwrap"
        );

        // check wrapper balance
        assertEq(wrappedShort.totalSupply(), 8e6);
        assertEq(wrappedShort.balanceOf(writer), 8e6, "wrapper balance before unwrap");

        // When writer unwraps 5 options
        vm.prank(writer);
        wrappedShort.unwrapShorts(5e6);

        // Then
        // check option balances
        assertOptionBalances(writer, optionTokenId, 10e6, 7e6, 0, "writer after unwrap");
        assertOptionBalances(
            address(wrappedShort), optionTokenId, 0, 3e6, 0, "wrapper after unwrap"
        );

        // check wrapper balance
        assertEq(wrappedShort.totalSupply(), 3e6, "wrapper totalSupply after unwrap");
        assertEq(wrappedShort.balanceOf(writer), 3e6, "wrapper balance after unwrap");
    }

    function test_unwrapShorts_many() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        uint256[] memory shortTokenIds = new uint256[](numOptions);
        ClarityWrappedShort[] memory wrappedShorts = new ClarityWrappedShort[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeNewCall(
                address(WETHLIKE),
                address(FRAXLIKE),
                FRI1,
                (1750 + i) * 10 ** 18,
                true,
                10e6
            );
            shortTokenIds[i] = optionTokenIds[i].longToShort();
            wrappedShorts[i] =
                ClarityWrappedShort(factory.deployWrappedShort(shortTokenIds[i]));
            clarity.approve(
                address(wrappedShorts[i]), shortTokenIds[i], type(uint256).max
            );
            wrappedShorts[i].wrapShorts(uint64((10 - i) * 10 ** 6));

            // pre checks
            // check option balances
            assertOptionBalances(
                writer, optionTokenIds[i], 10e6, i * 10 ** 6, 0, "writer before unwrap"
            );
            assertOptionBalances(
                address(wrappedShorts[i]),
                optionTokenIds[i],
                0,
                (10 - i) * 10 ** 6,
                0,
                "wrapper before unwrap"
            );

            // check wrapper balance
            assertEq(
                wrappedShorts[i].totalSupply(),
                (10 - i) * 10 ** 6,
                "wrapper totalSupply before unwrap"
            );
            assertEq(
                wrappedShorts[i].balanceOf(writer),
                (10 - i) * 10 ** 6,
                "wrapper balance before unwrap"
            );

            // When
            wrappedShorts[i].unwrapShorts(uint64(((10 - i) * 10 ** 6) - (i * 10 ** 5)));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            assertOptionBalances(
                writer,
                optionTokenIds[i],
                10e6,
                10e6 - (i * 10 ** 5),
                0,
                "writer after unwrap"
            );
            assertOptionBalances(
                address(wrappedShorts[i]),
                optionTokenIds[i],
                0,
                i * 10 ** 5,
                0,
                "wrapper after unwrap"
            );

            // check wrapper balance
            assertEq(
                wrappedShorts[i].totalSupply(),
                i * 10 ** 5,
                "wrapper totalSupply after unwrap"
            );
            assertEq(
                wrappedShorts[i].balanceOf(writer),
                i * 10 ** 5,
                "wrapper balance after unwrap"
            );
        }
    }

    // Events

    function testEvent_unwrapShorts() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);

        // Then
        vm.expectEmit(true, true, true, true);
        emit IWrappedShortEvents.ClarityShortsUnwrapped(writer, shortTokenId, 5.000001e6);

        // When
        wrappedShort.unwrapShorts(5.000001e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_unwrapShorts_whenAmountZero() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(IOptionErrors.UnwrapAmountZero.selector);

        // When
        vm.prank(writer);
        wrappedShort.unwrapShorts(0);
    }

    function testRevert_unwrapShorts_whenCallerHoldsInsufficientWrappedShorts() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(shortTokenId));
        clarity.approve(address(wrappedShort), shortTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.InsufficientWrappedBalance.selector, shortTokenId, 8e6
            )
        );

        // When
        vm.prank(writer);
        wrappedShort.unwrapShorts(8.000001e6);
    }

    /////////
    // function redeemShorts(uint256 amount) external;

    // TODO
}
