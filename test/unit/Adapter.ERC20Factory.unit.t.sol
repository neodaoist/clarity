// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Interfaces
import {IClarityERC20Factory} from "../../src/interface/adapter/IClarityERC20Factory.sol";
import {IClarityWrappedLong} from "../../src/interface/adapter/IClarityWrappedLong.sol";
import {IClarityWrappedShort} from "../../src/interface/adapter/IClarityWrappedShort.sol";

// Contracts Under Test
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";
import {ClarityWrappedLong} from "../../src/adapter/ClarityWrappedLong.sol";
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

contract AdapterTest is BaseClarityMarketsTest {
    /////////

    using LibToken for uint256;

    ClarityERC20Factory internal factory;
    ClarityWrappedLong internal wrappedLong;
    ClarityWrappedShort internal wrappedShort;

    function setUp() public override {
        super.setUp();

        // deploy factory
        factory = new ClarityERC20Factory(clarity);
    }

    /////////
    // Construction

    function test_initial() public {
        assertEq(address(factory.clarity()), address(clarity));
    }

    /////////
    // function deployWrappedLong(uint256 optionTokenId) external returns (address wrapperAddress);

    //
    function test_deployWrappedLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        vm.stopPrank();

        // When writer deploys ClarityWrappedLong
        vm.prank(writer);
        address wrappedLongAddress = factory.deployWrappedLong(optionTokenId);

        // Then
        // check deployed wrapped long
        wrappedLong = ClarityWrappedLong(wrappedLongAddress);

        string memory expectedName =
            string(abi.encodePacked("w", clarity.names(optionTokenId)));
        assertEq(wrappedLong.name(), expectedName, "wrapper name");
        assertEq(wrappedLong.symbol(), expectedName, "wrapper symbol");
        assertEq(
            wrappedLong.decimals(), clarity.decimals(optionTokenId), "wrapper decimals"
        );

        assertEq(wrappedLong.optionTokenId(), optionTokenId, "wrapper optionTokenId");
        // assertEq(wrapper.option(), clarity.option(optionTokenId)); // TODO consider adding
        IOptionToken.Option memory option = wrappedLong.option();
        assertEq(option.optionType, IOptionToken.OptionType.CALL, "wrapper optionType");
        assertEq(
            option.exerciseStyle,
            IOptionToken.ExerciseStyle.AMERICAN,
            "wrapper exerciseStyle"
        );
        assertEq(
            option.exerciseWindow.exerciseTimestamp,
            americanExWeeklies[0][0],
            "wrapper exerciseWindow.exerciseTimestamp"
        );
        assertEq(
            option.exerciseWindow.expiryTimestamp,
            americanExWeeklies[0][1],
            "wrapper exerciseWindow.expiryTimestamp"
        );

        // check factory state
        assertEq(
            factory.wrapperFor(optionTokenId),
            wrappedLongAddress,
            "wrapper address from factory"
        );
    }

    function test_deployWrappedLong_many() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        ClarityWrappedLong[] memory wrappedLongs = new ClarityWrappedLong[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeCall(
                address(WETHLIKE),
                address(USDCLIKE),
                americanExWeeklies[0],
                (1750 + i) * 10 ** 18,
                10e6
            );

            // When writer deploys ClarityWrappedLong
            wrappedLongs[i] =
                ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check deployed wrapper
            string memory expectedName =
                string(abi.encodePacked("w", clarity.names(optionTokenIds[i])));
            assertEq(wrappedLongs[i].name(), expectedName, "wrapper name");
            assertEq(wrappedLongs[i].symbol(), expectedName, "wrapper symbol");
            assertEq(
                wrappedLongs[i].decimals(),
                clarity.decimals(optionTokenIds[i]),
                "wrapper decimals"
            );

            assertEq(
                wrappedLongs[i].optionTokenId(),
                optionTokenIds[i],
                "wrapper optionTokenId"
            );
            IOptionToken.Option memory option = wrappedLongs[i].option();
            assertEq(
                option.optionType, IOptionToken.OptionType.CALL, "wrapper optionType"
            );
            assertEq(
                option.exerciseStyle,
                IOptionToken.ExerciseStyle.AMERICAN,
                "wrapper exerciseStyle"
            );
            assertEq(
                option.exerciseWindow.exerciseTimestamp,
                americanExWeeklies[0][0],
                "wrapper exerciseWindow.exerciseTimestamp"
            );
            assertEq(
                option.exerciseWindow.expiryTimestamp,
                americanExWeeklies[0][1],
                "wrapper exerciseWindow.expiryTimestamp"
            );

            // check factory state
            assertEq(
                factory.wrapperFor(optionTokenIds[i]),
                address(wrappedLongs[i]),
                "wrapper address from factory"
            );
        }
    }

    // Events

    function testEvent_deployWrappedLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
        );

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit IClarityWrappedLong.ClarityWrappedLongDeployed(optionTokenId, address(0x1234));

        // When
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_deployWrappedLong_whenOptionDoesNotExist() public {
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, 456)
        );

        vm.prank(writer);
        factory.deployWrappedLong(456);
    }

    function testRevert_deployWrappedLong_whenWrapperAlreadyDeployed() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.WrappedLongAlreadyDeployed.selector, optionTokenId
            )
        );

        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    function testRevert_deployWrappedLong_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionExpired.selector,
                optionTokenId,
                uint32(block.timestamp)
            )
        );

        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    /////////
    // function deployWrappedShort(uint256 shortTokenId) external returns (address wrapperAddress);

    // TODO

    /////////
    // function wrapperFor(uint256 tokenId) external view returns (address wrapperAddress);

    // TODO
}
