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

contract ERC20FactoryTest is BaseClarityMarketsTest {
    /////////

    using LibPosition for uint248;
    using LibPosition for uint256;

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

    function test_deployWrappedLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );

        // When writer deploys ClarityWrappedLong
        address wrappedLongAddress = factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();

        // Then
        // check deployed wrapped long
        wrappedLong = ClarityWrappedLong(wrappedLongAddress);

        string memory expectedName = string.concat("w", clarity.names(optionTokenId));
        assertEq(wrappedLong.name(), expectedName, "wrapper name");
        assertEq(wrappedLong.symbol(), expectedName, "wrapper symbol");
        assertEq(
            wrappedLong.decimals(), clarity.decimals(optionTokenId), "wrapper decimals"
        );

        assertEq(wrappedLong.optionTokenId(), optionTokenId, "wrapper optionTokenId");
        // assertEq(wrapper.option(), clarity.option(optionTokenId)); // TODO consider adding
        IOption.Option memory option = wrappedLong.option();
        assertEq(option.optionType, IOption.OptionType.CALL, "wrapper optionType");
        assertEq(
            option.exerciseStyle, IOption.ExerciseStyle.AMERICAN, "wrapper exerciseStyle"
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
                address(FRAXLIKE),
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
                string.concat("w", clarity.names(optionTokenIds[i]));
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
            IOption.Option memory option = wrappedLongs[i].option();
            assertEq(option.optionType, IOption.OptionType.CALL, "wrapper optionType");
            assertEq(
                option.exerciseStyle,
                IOption.ExerciseStyle.AMERICAN,
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
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit IClarityWrappedLong.ClarityWrappedLongDeployed(
            optionTokenId, address(0x1234)
        );

        // When
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_deployWrappedLong_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1750e18,
            optionType: IOption.OptionType.CALL
        }).hashToId();

        // Then
        vm.expectRevert(abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, optionTokenId));

        // When
        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    function testRevert_deployWrappedLong_whenWrapperAlreadyDeployed() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.WrappedLongAlreadyDeployed.selector, optionTokenId
            )
        );

        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    function testRevert_deployWrappedLong_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector,
                optionTokenId,
                uint32(block.timestamp)
            )
        );

        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    /////////
    // function deployWrappedShort(uint256 shortTokenId) external returns (address wrapperAddress);

    //
    function test_deployWrappedShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();

        // When writer deploys ClarityWrappedShort
        address wrappedShortAddress = factory.deployWrappedShort(shortTokenId);
        vm.stopPrank();

        // Then
        // check deployed wrapped long
        wrappedShort = ClarityWrappedShort(wrappedShortAddress);

        string memory expectedName = string.concat("w", clarity.names(shortTokenId));
        assertEq(wrappedShort.name(), expectedName, "wrapper name");
        assertEq(wrappedShort.symbol(), expectedName, "wrapper symbol");
        assertEq(
            wrappedShort.decimals(), clarity.decimals(optionTokenId), "wrapper decimals"
        );

        assertEq(wrappedShort.optionTokenId(), optionTokenId, "wrapper optionTokenId");
        IOption.Option memory option = wrappedShort.option();
        assertEq(option.optionType, IOption.OptionType.CALL, "wrapper optionType");
        assertEq(
            option.exerciseStyle, IOption.ExerciseStyle.AMERICAN, "wrapper exerciseStyle"
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
            factory.wrapperFor(shortTokenId),
            wrappedShortAddress,
            "wrapper address from factory"
        );
    }

    function test_deployWrappedShort_many() public {
        uint256 numOptions = 10;
        uint256[] memory optionTokenIds = new uint256[](numOptions);
        uint256[] memory shortTokenIds = new uint256[](numOptions);
        ClarityWrappedShort[] memory wrappedShorts = new ClarityWrappedShort[](numOptions);

        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeCall(
                address(WETHLIKE),
                address(FRAXLIKE),
                americanExWeeklies[0],
                (1750 + i) * 10 ** 18,
                10e6
            );
            shortTokenIds[i] = optionTokenIds[i].longToShort();

            // When writer deploys ClarityWrappedShort
            wrappedShorts[i] =
                ClarityWrappedShort(factory.deployWrappedShort(shortTokenIds[i]));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check deployed wrapper
            string memory expectedName =
                string.concat("w", clarity.names(shortTokenIds[i]));
            assertEq(wrappedShorts[i].name(), expectedName, "wrapper name");
            assertEq(wrappedShorts[i].symbol(), expectedName, "wrapper symbol");
            assertEq(
                wrappedShorts[i].decimals(),
                clarity.decimals(shortTokenIds[i]),
                "wrapper decimals"
            );

            assertEq(
                wrappedShorts[i].optionTokenId(),
                optionTokenIds[i],
                "wrapper optionTokenId"
            );
            IOption.Option memory option = wrappedShorts[i].option();
            assertEq(option.optionType, IOption.OptionType.CALL, "wrapper optionType");
            assertEq(
                option.exerciseStyle,
                IOption.ExerciseStyle.AMERICAN,
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
                factory.wrapperFor(shortTokenIds[i]),
                address(wrappedShorts[i]),
                "wrapper address from factory"
            );
        }
    }

    // Events

    function testEvent_deployWrappedShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit IClarityWrappedShort.ClarityWrappedShortDeployed(
            shortTokenId, address(0x1234)
        );

        // When
        factory.deployWrappedShort(shortTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_deployWrappedShort_whenTokenTypeIsLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );

        // Then
        vm.expectRevert(abi.encodeWithSelector(IOptionErrors.TokenIdNotShort.selector, optionTokenId));

        // When
        factory.deployWrappedShort(optionTokenId);
        vm.stopPrank();        
    }

    function testRevert_deployWrappedShort_whenTokenTypeIsAssignedShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

        // Then
        vm.expectRevert(abi.encodeWithSelector(IOptionErrors.TokenIdNotShort.selector, assignedShortTokenId));

        // When
        factory.deployWrappedShort(assignedShortTokenId);
        vm.stopPrank();        
    }

    function testRevert_deployWrappedShort_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1750e18,
            optionType: IOption.OptionType.CALL
        }).hashToId();

        // Then
        vm.expectRevert(abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, optionTokenId));

        // When
        vm.prank(writer);
        factory.deployWrappedShort(optionTokenId.longToShort());
    }

    function testRevert_deployWrappedShort_whenWrapperAlreadyDeployed() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        factory.deployWrappedShort(shortTokenId);
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.WrappedShortAlreadyDeployed.selector, shortTokenId
            )
        );

        // When
        vm.prank(writer);
        factory.deployWrappedShort(shortTokenId);
    }

    function testRevert_deployWrappedShort_whenOptionExpired() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionExpired.selector,
                optionTokenId,
                uint32(block.timestamp)
            )
        );

        // When
        vm.prank(writer);
        factory.deployWrappedShort(shortTokenId);
    }

    function testRevert_deployWrappedShort_whenShortHasBeenAssigned() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeCall(
            address(WETHLIKE), address(FRAXLIKE), americanExWeeklies[0], 1750e18, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();

        vm.warp(americanExWeeklies[0][0]);

        FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
        clarity.exercise(optionTokenId, 0.000001e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(abi.encodeWithSelector(IOptionErrors.ShortAlreadyAssigned.selector, shortTokenId));

        // When
        vm.prank(writer);
        factory.deployWrappedShort(shortTokenId);
    }

    /////////
    // function wrapperFor(uint256 tokenId) external view returns (address wrapperAddress);

    // TODO
}
