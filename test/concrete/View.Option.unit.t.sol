// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTest.t.sol";

// Libraries
import {LibOption} from "../../src/library/LibOption.sol";
import {LibPosition} from "../../src/library/LibPosition.sol";

// Views Under Test
import {IOption} from "../../src/interface/option/IOption.sol";

contract OptionViewTest is BaseUnitTest {
    /////////

    using LibOption for uint32[];

    using LibPosition for uint248;
    using LibPosition for uint256;

    /////////
    // function optionTokenId(
    //     address baseAsset,
    //     address quoteAsset,
    //     uint32[] calldata exerciseWindows,
    //     uint256 strike,
    //     bool isCall
    // ) external view returns (uint256 optionTokenId);

    function test_optionTokenId_whenCall_andAmerican() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 expectedOptionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        uint256 actualOptionTokenId = clarity.optionTokenId({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiries: expiries,
            strike: 1950e18,
            optionType: uint8(IOption.OptionType.CALL),
            exerciseStyle: uint8(IOption.ExerciseStyle.AMERICAN)
        });

        assertEq(actualOptionTokenId, expectedOptionTokenId);
    }

    function test_optionTokenId_whenPut_andAmerican() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        uint256 expectedOptionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        uint256 actualOptionTokenId = clarity.optionTokenId({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiries: expiries,
            strike: 1950e18,
            optionType: uint8(IOption.OptionType.PUT),
            exerciseStyle: uint8(IOption.ExerciseStyle.AMERICAN)
        });

        assertEq(actualOptionTokenId, expectedOptionTokenId);
    }

    function test_optionTokenId_whenCall_andEuropean() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 expectedOptionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });
        vm.stopPrank();

        uint256 actualOptionTokenId = clarity.optionTokenId({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiries: expiries,
            strike: 1950e18,
            optionType: uint8(IOption.OptionType.CALL),
            exerciseStyle: uint8(IOption.ExerciseStyle.EUROPEAN)
        });

        assertEq(actualOptionTokenId, expectedOptionTokenId);
    }

    function test_optionTokenId_whenPut_andEuropean() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        uint256 expectedOptionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });
        vm.stopPrank();

        uint256 actualOptionTokenId = clarity.optionTokenId({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiries: expiries,
            strike: 1950e18,
            optionType: uint8(IOption.OptionType.PUT),
            exerciseStyle: uint8(IOption.ExerciseStyle.EUROPEAN)
        });

        assertEq(actualOptionTokenId, expectedOptionTokenId);
    }

    // Sad Paths

    function testRevert_optionTokenId_whenOptionDoesNotExist() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        }).hashToId();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        clarity.optionTokenId({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiries: expiries,
            strike: 1950e18,
            optionType: uint8(IOption.OptionType.CALL),
            exerciseStyle: uint8(IOption.ExerciseStyle.AMERICAN)
        });
    }

    /////////
    // function option(uint256 optionTokenId) external view returns (Option memory
    // option);

    function test_option_whenCall_andAmerican() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        IOption.Option memory expectedOption = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });

        assertEq(clarity.option(optionTokenId), expectedOption);
    }

    function test_option_whenPut_andAmerican() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        vm.stopPrank();

        IOption.Option memory expectedOption = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        });

        assertEq(clarity.option(optionTokenId), expectedOption);
    }

    function test_option_whenCall_andEuropean() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });
        vm.stopPrank();

        IOption.Option memory expectedOption = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.EUROPEAN
        });

        assertEq(clarity.option(optionTokenId), expectedOption);
    }

    function test_option_whenPut_andEuropean() public {
        uint32[] memory expiries = new uint32[](1);
        expiries[0] = FRI1;

        vm.startPrank(writer);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewPut({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            allowEarlyExercise: false,
            optionAmount: 1e6
        });
        vm.stopPrank();

        IOption.Option memory expectedOption = IOption.Option({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.PUT,
            exerciseStyle: IOption.ExerciseStyle.EUROPEAN
        });

        assertEq(clarity.option(optionTokenId), expectedOption);
    }

    // Sad Paths

    function testRevert_option_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1950e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        }).hashToId();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        clarity.option(optionTokenId);
    }
}
