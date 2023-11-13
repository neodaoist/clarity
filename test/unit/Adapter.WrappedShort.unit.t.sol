// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Interfaces
import {IClarityWrappedShort} from "../../src/interface/adapter/IClarityWrappedShort.sol";

// Contracts Under Test
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

contract WrappedShortTest is BaseClarityMarketsTest {
    /////////

    using LibPosition for uint256;

    ClarityERC20Factory internal factory;
    ClarityWrappedShort internal wrappedShort;

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
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId.longToShort()));
        vm.stopPrank();

        // pre checks
        assertOptionBalances(writer, optionTokenId, 10e6, 10e6, 0, "before wrap");

        // When writer wraps 8 options
        vm.startPrank(writer);
        clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);
        wrappedShort.wrapShorts(8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertOptionBalances(writer, optionTokenId, 10e6, 2e6, 0, "after wrap");
        assertOptionBalances(address(wrappedShort), optionTokenId, 8e6, 0, 0, "after wrap");

        // check wrapper balance
        assertEq(wrappedShort.totalSupply(), 8e6, "wrapper totalSupply after wrap");
        assertEq(wrappedShort.balanceOf(writer), 8e6, "wrapper balance after wrap");
    }

    // function test_wrapShorts_manyOptions() public {
    //     uint256 numOptions = 10;
    //     uint256[] memory optionTokenIds = new uint256[](numOptions);
    //     ClarityWrappedShort[] memory wrappedShorts = new ClarityWrappedShort[](numOptions);

    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     for (uint256 i = 0; i < numOptions; i++) {
    //         optionTokenIds[i] = clarity.writeCall(
    //             address(WETHLIKE),
    //             address(USDCLIKE),
    //             americanExWeeklies[0],
    //             (1750 + i) * 10 ** 18,
    //             10e6
    //         );
    //         wrappedShorts[i] =
    //             ClarityWrappedShort(factory.deployWrappedShort(optionTokenIds[i]));

    //         // pre checks
    //         // check option balances
    //         assertOptionBalances(
    //             writer, optionTokenIds[i], 10e6, 10e6, 0, "writer before wrap"
    //         );

    //         // When writer wraps options
    //         clarity.approve(
    //             address(wrappedShorts[i]), optionTokenIds[i], type(uint256).max
    //         );
    //         wrappedShorts[i].wrapShorts(uint64((10 - i) * 10 ** 6));
    //     }
    //     vm.stopPrank();

    //     // Then
    //     for (uint256 i = 0; i < numOptions; i++) {
    //         // check option balances
    //         assertOptionBalances(
    //             writer, optionTokenIds[i], i * 10 ** 6, 10e6, 0, "writer after wrap"
    //         );
    //         assertOptionBalances(
    //             address(wrappedShorts[i]),
    //             optionTokenIds[i],
    //             (10 - i) * 10 ** 6,
    //             0,
    //             0,
    //             "wrapper after wrap"
    //         );

    //         // check wrapper balances
    //         assertEq(
    //             wrappedShorts[i].totalSupply(),
    //             (10 - i) * 10 ** 6,
    //             "wrapper totalSupply after wrap"
    //         );
    //         assertEq(
    //             wrappedShorts[i].balanceOf(writer),
    //             (10 - i) * 10 ** 6,
    //             "wrapper balance after wrap"
    //         );
    //     }
    // }

    // // TODO test_wrapShorts_manyOptions_manyCallers

    // // Events

    // function testEvent_wrapShorts() public {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);

    //     // Then
    //     vm.expectEmit(true, true, true, true);
    //     emit IClarityWrappedShort.ClarityShortsWrapped(writer, optionTokenId, 8e6);

    //     // When
    //     wrappedShort.wrapShorts(8e6);
    //     vm.stopPrank();
    // }

    // // Sad Paths

    // function testRevert_wrapShorts_whenAmountZero() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     vm.stopPrank();

    //     vm.expectRevert(IOptionErrors.WrapAmountZero.selector);

    //     vm.prank(writer);
    //     wrappedShort.wrapShorts(0);
    // }

    // function testRevert_wrapShorts_whenOptionExpired() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     vm.stopPrank();

    //     vm.warp(americanExWeeklies[0][1] + 1 seconds);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IOptionErrors.OptionExpired.selector,
    //             optionTokenId,
    //             uint32(block.timestamp)
    //         )
    //     );

    //     vm.prank(writer);
    //     wrappedShort.wrapShorts(10e6);
    // }

    // TODO testRevert_wrapShorts_whenOptionDoesNotExist_whenShortHasBeenAssigned

    // function testRevert_wrapShorts_whenCallerHoldsInsufficientShorts() public {
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     vm.stopPrank();

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IOptionErrors.InsufficientShortBalance.selector, optionTokenId, 10e6
    //         )
    //     );

    //     vm.prank(writer);
    //     wrappedShort.wrapShorts(10.000001e6);
    // }

    // function testRevert_wrapShorts_whenCallerHasGrantedInsufficientClearinghouseApproval()
    //     public
    // {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));

    //     // And insufficient Clearinghouse approval has been granted to Factory
    //     clarity.approve(address(wrappedShort), optionTokenId, 8e6 - 1);

    //     // Then
    //     vm.expectRevert(stdError.arithmeticError);

    //     // When
    //     wrappedShort.wrapShorts(8e6);
    //     vm.stopPrank();
    // }

    // /////////
    // // function unwrapShorts(uint256 amount) external;

    // function test_unwrapShorts() public {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);
    //     wrappedShort.wrapShorts(8e6);
    //     vm.stopPrank();

    //     // pre checks
    //     // check option balances
    //     assertOptionBalances(writer, optionTokenId, 2e6, 10e6, 0, "writer before unwrap");
    //     assertOptionBalances(
    //         address(wrappedShort), optionTokenId, 8e6, 0, 0, "wrapper before unwrap"
    //     );

    //     // check wrapper balance
    //     assertEq(wrappedShort.totalSupply(), 8e6);
    //     assertEq(wrappedShort.balanceOf(writer), 8e6, "wrapper balance before unwrap");

    //     // When writer unwraps 5 options
    //     vm.prank(writer);
    //     wrappedShort.unwrapShorts(5e6);

    //     // Then
    //     // check option balances
    //     assertOptionBalances(writer, optionTokenId, 7e6, 10e6, 0, "writer after unwrap");
    //     assertOptionBalances(
    //         address(wrappedShort), optionTokenId, 3e6, 0, 0, "wrapper after unwrap"
    //     );

    //     // check wrapper balance
    //     assertEq(wrappedShort.totalSupply(), 3e6, "wrapper totalSupply after unwrap");
    //     assertEq(wrappedShort.balanceOf(writer), 3e6, "wrapper balance after unwrap");
    // }

    // function test_unwrapShorts_many() public {
    //     uint256 numOptions = 10;
    //     uint256[] memory optionTokenIds = new uint256[](numOptions);
    //     ClarityWrappedShort[] memory wrappedShorts = new ClarityWrappedShort[](numOptions);

    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     for (uint256 i = 0; i < numOptions; i++) {
    //         optionTokenIds[i] = clarity.writeCall(
    //             address(WETHLIKE),
    //             address(USDCLIKE),
    //             americanExWeeklies[0],
    //             (1750 + i) * 10 ** 18,
    //             10e6
    //         );
    //         wrappedShorts[i] =
    //             ClarityWrappedShort(factory.deployWrappedShort(optionTokenIds[i]));
    //         clarity.approve(
    //             address(wrappedShorts[i]), optionTokenIds[i], type(uint256).max
    //         );
    //         wrappedShorts[i].wrapShorts(uint64((10 - i) * 10 ** 6));

    //         // pre checks
    //         // check option balances
    //         assertOptionBalances(
    //             writer, optionTokenIds[i], i * 10 ** 6, 10e6, 0, "writer before unwrap"
    //         );
    //         assertOptionBalances(
    //             address(wrappedShorts[i]),
    //             optionTokenIds[i],
    //             (10 - i) * 10 ** 6,
    //             0,
    //             0,
    //             "wrapper before unwrap"
    //         );

    //         // check wrapper balance
    //         assertEq(
    //             wrappedShorts[i].totalSupply(),
    //             (10 - i) * 10 ** 6,
    //             "wrapper totalSupply before unwrap"
    //         );
    //         assertEq(
    //             wrappedShorts[i].balanceOf(writer),
    //             (10 - i) * 10 ** 6,
    //             "wrapper balance before unwrap"
    //         );

    //         // When
    //         wrappedShorts[i].unwrapShorts(uint64(((10 - i) * 10 ** 6) - (i * 10 ** 5)));
    //     }
    //     vm.stopPrank();

    //     // Then
    //     for (uint256 i = 0; i < numOptions; i++) {
    //         // check option balances
    //         assertOptionBalances(
    //             writer,
    //             optionTokenIds[i],
    //             10e6 - (i * 10 ** 5),
    //             10e6,
    //             0,
    //             "writer after unwrap"
    //         );
    //         assertOptionBalances(
    //             address(wrappedShorts[i]),
    //             optionTokenIds[i],
    //             i * 10 ** 5,
    //             0,
    //             0,
    //             "wrapper after unwrap"
    //         );

    //         // check wrapper balance
    //         assertEq(
    //             wrappedShorts[i].totalSupply(),
    //             i * 10 ** 5,
    //             "wrapper totalSupply after unwrap"
    //         );
    //         assertEq(
    //             wrappedShorts[i].balanceOf(writer),
    //             i * 10 ** 5,
    //             "wrapper balance after unwrap"
    //         );
    //     }
    // }

    // // Events

    // function testEvent_unwrapShorts() public {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);
    //     wrappedShort.wrapShorts(8e6);

    //     // Then
    //     vm.expectEmit(true, true, true, true);
    //     emit IClarityWrappedShort.ClarityShortsUnwrapped(writer, optionTokenId, 5.000001e6);

    //     // When
    //     wrappedShort.unwrapShorts(5.000001e6);
    //     vm.stopPrank();
    // }

    // // Sad Paths

    // function testRevert_unwrapShorts_whenAmountZero() public {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);
    //     wrappedShort.wrapShorts(8e6);
    //     vm.stopPrank();

    //     // Then
    //     vm.expectRevert(IOptionErrors.UnwrapAmountZero.selector);

    //     // When
    //     vm.prank(writer);
    //     wrappedShort.unwrapShorts(0);
    // }

    // function testRevert_unwrapShorts_whenCallerHoldsInsufficientWrappedShorts() public {
    //     // Given
    //     vm.startPrank(writer);
    //     WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
    //     uint256 optionTokenId = clarity.writeCall(
    //         address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
    //     );
    //     wrappedShort = ClarityWrappedShort(factory.deployWrappedShort(optionTokenId));
    //     clarity.approve(address(wrappedShort), optionTokenId, type(uint256).max);
    //     wrappedShort.wrapShorts(8e6);
    //     vm.stopPrank();

    //     // Then
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IOptionErrors.InsufficientWrappedBalance.selector, optionTokenId, 8e6
    //         )
    //     );

    //     // When
    //     vm.prank(writer);
    //     wrappedShort.unwrapShorts(8.000001e6);
    // }

    /////////
    // function exerciseShorts(uint256 amount) external;

    // TODO
}
