// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";
import {ClarityWrappedLong} from "../../src/adapter/ClarityWrappedLong.sol";
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

import "../BaseClarityMarkets.t.sol";

contract AdapterTest is BaseClarityMarketsTest {
    /////////

    using LibToken for uint256;

    ClarityERC20Factory internal factory;
    ClarityWrappedLong internal longWrapper;
    ClarityWrappedShort internal shortWrapper;

    function setUp() public override {
        super.setUp();

        // deploy factory
        factory = new ClarityERC20Factory(clarity);
    }

    /////////

    function test_initial() public {
        assertEq(address(factory.clarity()), address(clarity));
    }

    //
    function test_deployWrappedLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        vm.stopPrank();

        // pre checks
        // check option balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 10e6, "writer long balance before wrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance before wrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance before wrap"
        );

        // When writer deploys ClarityWrappedLong
        vm.prank(writer);
        address longWrapperAddress = factory.deployWrappedLong(optionTokenId);

        // Then
        // check deployed wrapper
        ClarityWrappedLong wrapper = ClarityWrappedLong(longWrapperAddress);
        string memory expectedName = string(abi.encodePacked("w", clarity.names(optionTokenId)));
        assertEq(wrapper.name(), expectedName, "wrapper name");
        assertEq(wrapper.symbol(), expectedName, "wrapper symbol");
        assertEq(wrapper.decimals(), clarity.decimals(optionTokenId), "wrapper decimals");
        assertEq(wrapper.optionTokenId(), optionTokenId, "wrapper optionTokenId");
        // assertEq(wrapper.option(), clarity.option(optionTokenId));
        assertEq(wrapper.optionType(), IOptionToken.OptionType.CALL, "wrapper optionType");
        assertEq(wrapper.exerciseStyle(), IOptionToken.ExerciseStyle.AMERICAN, "wrapper exerciseStyle");
        assertEq(
            wrapper.exerciseWindow().exerciseTimestamp,
            americanExWeeklies[0][0],
            "wrapper exerciseWindow.exerciseTimestamp"
        );
        assertEq(
            wrapper.exerciseWindow().expiryTimestamp,
            americanExWeeklies[0][1],
            "wrapper exerciseWindow.expiryTimestamp"
        );

        // check factory state
        assertEq(factory.wrapperFor(optionTokenId), longWrapperAddress, "wrapper address from factory");
    }

    function test_deployedWrappedLong_andWrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        longWrapper = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        // pre checks
        // check option balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 10e6, "writer long balance before wrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance before wrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance before wrap"
        );

        // When writer wraps 8 options
        vm.startPrank(writer);
        clarity.approve(address(longWrapper), optionTokenId, type(uint256).max);
        longWrapper.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        // check option balances
        assertEq(clarity.balanceOf(writer, optionTokenId), 2e6, "writer long balance after wrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance after wrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance after wrap"
        );

        // check wrapper balance
        assertEq(longWrapper.totalSupply(), 8e6);
        assertEq(longWrapper.balanceOf(writer), 8e6, "wrapper balance after wrap");
    }
}