// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Harness
import "../BaseUnitTestSuite.t.sol";

// Interfaces
import {IERC20Factory} from "../../src/interface/adapter/IERC20Factory.sol";
import {IWrappedLongActions} from "../../src/interface/adapter/IWrappedLongActions.sol";
import {IWrappedLongEvents} from "../../src/interface/adapter/IWrappedLongEvents.sol";
import {IWrappedShortActions} from "../../src/interface/adapter/IWrappedShortActions.sol";
import {IWrappedShortEvents} from "../../src/interface/adapter/IWrappedShortEvents.sol";

// Contracts
import {ClarityWrappedLong} from "../../src/adapter/ClarityWrappedLong.sol";
import {ClarityWrappedShort} from "../../src/adapter/ClarityWrappedShort.sol";

// Contract Under Test
import {ClarityERC20Factory} from "../../src/adapter/ClarityERC20Factory.sol";

contract ERC20FactoryTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint248;
    using LibPosition for uint256;

    ClarityERC20Factory private factory;
    ClarityWrappedLong private wrappedLong;
    ClarityWrappedShort private wrappedShort;

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
    // function deployWrappedLong(uint256 optionTokenId) external returns (address
    // wrapperAddress);

    function test_deployWrappedLong() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
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
        assertEq(clarity.option(optionTokenId), wrappedLong.option(), "wrapper option");

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
            optionTokenIds[i] = clarity.writeNewCall(
                address(WETHLIKE),
                address(FRAXLIKE),
                FRI1,
                (1750 + i) * 10 ** 18,
                true,
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
            assertEq(
                wrappedLongs[i].option(),
                clarity.option(optionTokenIds[i]),
                "wrapper option"
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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit IWrappedLongEvents.ClarityWrappedLongDeployed(optionTokenId, address(0x1234));

        // When
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_deployWrappedLong_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1750e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        }).hashToId();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        // When
        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    function testRevert_deployWrappedLong_whenWrapperAlreadyDeployed() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
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
        factory.deployWrappedLong(optionTokenId);
    }

    /////////
    // function deployWrappedShort(uint256 shortTokenId) external returns (address
    // wrapperAddress);

    //
    function test_deployWrappedShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
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
        assertEq(wrappedShort.option(), clarity.option(optionTokenId), "wrapper option");

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
            optionTokenIds[i] = clarity.writeNewCall(
                address(WETHLIKE),
                address(FRAXLIKE),
                FRI1,
                (1750 + i) * 10 ** 18,
                true,
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

            assertEq(
                wrappedShorts[i].option(),
                clarity.option(optionTokenIds[i]),
                "wrapper option"
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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit IWrappedShortEvents.ClarityWrappedShortDeployed(
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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.TokenIdNotShort.selector, optionTokenId)
        );

        // When
        factory.deployWrappedShort(optionTokenId);
        vm.stopPrank();
    }

    function testRevert_deployWrappedShort_whenTokenTypeIsAssignedShort() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 assignedShortTokenId = optionTokenId.longToAssignedShort();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.TokenIdNotShort.selector, assignedShortTokenId
            )
        );

        // When
        factory.deployWrappedShort(assignedShortTokenId);
        vm.stopPrank();
    }

    function testRevert_deployWrappedShort_whenOptionDoesNotExist() public {
        uint256 optionTokenId = LibOption.paramsToHash({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1750e18,
            optionType: IOption.OptionType.CALL,
            exerciseStyle: IOption.ExerciseStyle.AMERICAN
        }).hashToId();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, optionTokenId
            )
        );

        // When
        vm.prank(writer);
        factory.deployWrappedShort(optionTokenId.longToShort());
    }

    function testRevert_deployWrappedShort_whenWrapperAlreadyDeployed() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();
        vm.stopPrank();

        vm.warp(FRI1 + 1 seconds);

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
        uint256 optionTokenId = clarity.writeNewCall(
            address(WETHLIKE), address(FRAXLIKE), FRI1, 1750e18, true, 10e6
        );
        uint256 shortTokenId = optionTokenId.longToShort();

        vm.warp(FRI1 - 1 seconds);

        FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
        clarity.exerciseLongs(optionTokenId, 0.000001e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.ShortAlreadyAssigned.selector, shortTokenId
            )
        );

        // When
        vm.prank(writer);
        factory.deployWrappedShort(shortTokenId);
    }

    /////////
    // function wrapperFor(uint256 tokenId) external view returns (address
    // wrapperAddress);

    // TODO
}
