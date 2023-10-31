// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Test Harness
import "../BaseClarityMarkets.t.sol";

// Interfaces
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
        address wrappedLongAddress = factory.deployWrappedLong(optionTokenId);

        // Then
        // check deployed wrapper
        ClarityWrappedLong wrapper = ClarityWrappedLong(wrappedLongAddress);
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
        assertEq(factory.wrapperFor(optionTokenId), wrappedLongAddress, "wrapper address from factory");
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
                address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], (1750 + i) * 10 ** 18, 10e6
            );

            // When writer deploys ClarityWrappedLong
            wrappedLongs[i] = ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check deployed wrapper
            string memory expectedName = string(abi.encodePacked("w", clarity.names(optionTokenIds[i])));
            assertEq(wrappedLongs[i].name(), expectedName, "wrapper name");
            assertEq(wrappedLongs[i].symbol(), expectedName, "wrapper symbol");
            assertEq(wrappedLongs[i].decimals(), clarity.decimals(optionTokenIds[i]), "wrapper decimals");
            assertEq(wrappedLongs[i].optionTokenId(), optionTokenIds[i], "wrapper optionTokenId");
            // assertEq(wrappedLongs[i].option(), clarity.option(optionTokenIds[i]));
            assertEq(wrappedLongs[i].optionType(), IOptionToken.OptionType.CALL, "wrapper optionType");
            assertEq(
                wrappedLongs[i].exerciseStyle(), IOptionToken.ExerciseStyle.AMERICAN, "wrapper exerciseStyle"
            );
            assertEq(
                wrappedLongs[i].exerciseWindow().exerciseTimestamp,
                americanExWeeklies[0][0],
                "wrapper exerciseWindow.exerciseTimestamp"
            );
            assertEq(
                wrappedLongs[i].exerciseWindow().expiryTimestamp,
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
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);

        // Then
        vm.expectEmit(true, false, true, true); // TODO fix once deterministic deploys
        emit ClarityWrappedLongDeployed(optionTokenId, address(0x1234));

        // When
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_deployWrappedLong_whenOptionDoesNotExist() public {
        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, 456));

        vm.prank(writer);
        factory.deployWrappedLong(456);
    }

    function testRevert_deployWrappedLong_whenWrapperAlreadyDeployed() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        factory.deployWrappedLong(optionTokenId);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.WrappedLongAlreadyDeployed.selector, optionTokenId)
        );

        vm.prank(writer);
        factory.deployWrappedLong(optionTokenId);
    }

    function testRevert_deployWrappedLong_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionExpired.selector, optionTokenId, uint32(block.timestamp)
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

    //////// ClarityWrappedLong

    /////////
    // function wrapLongs(uint256 optionAmount) external;

    function test_wrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
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
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        // check option balances
        // writer
        assertEq(clarity.balanceOf(writer, optionTokenId), 2e6, "writer long balance after wrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance after wrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance after wrap"
        );

        // wrapper
        address wrapperAddress = address(wrappedLong);
        assertEq(clarity.balanceOf(wrapperAddress, optionTokenId), 8e6, "wrapper long balance after wrap");
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToShort()),
            0,
            "wrapper short balance after wrap"
        );
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToAssignedShort()),
            0,
            "wrapper assigned short balance after wrap"
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
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeCall(
                address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], (1750 + i) * 10 ** 18, 10e6
            );
            wrappedLongs[i] = ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));

            // pre checks
            // check option balances
            assertEq(clarity.balanceOf(writer, optionTokenIds[i]), 10e6, "writer long balance before wrap");
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToShort()),
                10e6,
                "writer short balance before wrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToAssignedShort()),
                0,
                "writer assigned short balance before wrap"
            );

            // When writer wraps options
            clarity.approve(address(wrappedLongs[i]), optionTokenIds[i], type(uint256).max);
            wrappedLongs[i].wrapLongs((10 - i) * 10 ** 6);
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            // writer
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i]), i * 10 ** 6, "writer long balance after wrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToShort()),
                10e6,
                "writer short balance after wrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToAssignedShort()),
                0,
                "writer assigned short balance after wrap"
            );

            // wrapper
            address wrapperAddress = address(wrappedLongs[i]);
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i]),
                (10 - i) * 10 ** 6,
                "wrapper long balance after wrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToShort()),
                0,
                "wrapper short balance after wrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToAssignedShort()),
                0,
                "wrapper assigned short balance after wrap"
            );

            // check wrapper balances
            assertEq(wrappedLongs[i].totalSupply(), (10 - i) * 10 ** 6, "wrapper totalSupply after wrap");
            assertEq(wrappedLongs[i].balanceOf(writer), (10 - i) * 10 ** 6, "wrapper balance after wrap");
        }
    }

    // TODO test_wrapLongs_manyOptions_manyCallers

    // Events

    function testEvent_wrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);

        // Then
        vm.expectEmit(true, true, true, true);
        emit ClarityLongsWrapped(writer, optionTokenId, 8e6);

        // When
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_wrapLongs_whenAmountZero() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.expectRevert(OptionErrors.WrapAmountZero.selector);

        vm.prank(writer);
        wrappedLong.wrapLongs(0);
    }

    function testRevert_wrapLongs_whenOptionExpired() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.warp(americanExWeeklies[0][1] + 1 seconds);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionExpired.selector, optionTokenId, uint32(block.timestamp)
            )
        );

        vm.prank(writer);
        wrappedLong.wrapLongs(10e6);
    }

    function testRevert_wrapLongs_whenCallerHoldsInsufficientLongs() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.InsufficientLongBalance.selector, optionTokenId, 10e6)
        );

        vm.prank(writer);
        wrappedLong.wrapLongs(10.000001e6);
    }

    function testRevert_wrapLongs_whenCallerHasGrantedInsufficientClearinghouseApproval() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
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
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // pre checks
        // check option balances
        // writer
        assertEq(clarity.balanceOf(writer, optionTokenId), 2e6, "writer long balance before unwrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance before unwrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance before unwrap"
        );

        // wrapper
        address wrapperAddress = address(wrappedLong);
        assertEq(clarity.balanceOf(wrapperAddress, optionTokenId), 8e6, "wrapper long balance before unwrap");
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToShort()),
            0,
            "wrapper short balance before unwrap"
        );
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToAssignedShort()),
            0,
            "wrapper assigned short balance before unwrap"
        );

        // check wrapper balance
        assertEq(wrappedLong.totalSupply(), 8e6);
        assertEq(wrappedLong.balanceOf(writer), 8e6, "wrapper balance before unwrap");

        // When writer unwraps 5 options
        vm.prank(writer);
        wrappedLong.unwrapLongs(5e6);

        // Then
        // check option balances
        // writer
        assertEq(clarity.balanceOf(writer, optionTokenId), 7e6, "writer long balance after unwrap");
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToShort()), 10e6, "writer short balance after unwrap"
        );
        assertEq(
            clarity.balanceOf(writer, optionTokenId.longToAssignedShort()),
            0,
            "writer assigned short balance after unwrap"
        );

        // wrapper
        assertEq(clarity.balanceOf(wrapperAddress, optionTokenId), 3e6, "wrapper long balance after unwrap");
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToShort()),
            0,
            "wrapper short balance after unwrap"
        );
        assertEq(
            clarity.balanceOf(wrapperAddress, optionTokenId.longToAssignedShort()),
            0,
            "wrapper assigned short balance after unwrap"
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
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        for (uint256 i = 0; i < numOptions; i++) {
            optionTokenIds[i] = clarity.writeCall(
                address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], (1750 + i) * 10 ** 18, 10e6
            );
            wrappedLongs[i] = ClarityWrappedLong(factory.deployWrappedLong(optionTokenIds[i]));
            clarity.approve(address(wrappedLongs[i]), optionTokenIds[i], type(uint256).max);
            wrappedLongs[i].wrapLongs((10 - i) * 10 ** 6);

            // pre checks
            // check option balances
            // writer
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i]), i * 10 ** 6, "writer long balance before unwrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToShort()),
                10e6,
                "writer short balance before unwrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToAssignedShort()),
                0,
                "writer assigned short balance before unwrap"
            );

            // wrapper
            address wrapperAddress = address(wrappedLongs[i]);
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i]),
                (10 - i) * 10 ** 6,
                "wrapper long balance before unwrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToShort()),
                0,
                "wrapper short balance before unwrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToAssignedShort()),
                0,
                "wrapper assigned short balance before unwrap"
            );

            // check wrapper balance
            assertEq(wrappedLongs[i].totalSupply(), (10 - i) * 10 ** 6, "wrapper totalSupply before unwrap");
            assertEq(wrappedLongs[i].balanceOf(writer), (10 - i) * 10 ** 6, "wrapper balance before unwrap");

            // When
            wrappedLongs[i].unwrapLongs(((10 - i) * 10 ** 6) - (i * 10 ** 5));
        }
        vm.stopPrank();

        // Then
        for (uint256 i = 0; i < numOptions; i++) {
            // check option balances
            // writer
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i]),
                10e6 - (i * 10 ** 5),
                "writer long balance after unwrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToShort()),
                10e6,
                "writer short balance after unwrap"
            );
            assertEq(
                clarity.balanceOf(writer, optionTokenIds[i].longToAssignedShort()),
                0,
                "writer assigned short balance after unwrap"
            );

            // wrapper
            address wrapperAddress = address(wrappedLongs[i]);
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i]),
                i * 10 ** 5,
                "wrapper long balance after unwrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToShort()),
                0,
                "wrapper short balance after unwrap"
            );
            assertEq(
                clarity.balanceOf(wrapperAddress, optionTokenIds[i].longToAssignedShort()),
                0,
                "wrapper assigned short balance after unwrap"
            );

            // check wrapper balance
            assertEq(wrappedLongs[i].totalSupply(), i * 10 ** 5, "wrapper totalSupply after unwrap");
            assertEq(wrappedLongs[i].balanceOf(writer), i * 10 ** 5, "wrapper balance after unwrap");
        }
    }

    // Events

    function testEvent_unwrapLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);

        // Then
        vm.expectEmit(true, true, true, true);
        emit ClarityLongsUnwrapped(writer, optionTokenId, 5.000001e6);

        // When
        wrappedLong.unwrapLongs(5.000001e6);
        vm.stopPrank();
    }

    // Sad Paths

    function testRevert_unwrapLongs_whenAmountZero() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(OptionErrors.UnwrapAmountZero.selector);

        // When
        vm.prank(writer);
        wrappedLong.unwrapLongs(0);
    }

    function testRevert_unwrapLongs_whenCallerHoldsInsufficientWrappedLongs() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
        uint256 optionTokenId =
            clarity.writeCall(address(WETHLIKE), address(USDCLIKE), americanExWeeklies[0], 1750e18, 10e6);
        wrappedLong = ClarityWrappedLong(factory.deployWrappedLong(optionTokenId));
        clarity.approve(address(wrappedLong), optionTokenId, type(uint256).max);
        wrappedLong.wrapLongs(8e6);
        vm.stopPrank();

        // Then
        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.InsufficientWrappedBalance.selector, optionTokenId, 8e6)
        );

        // When
        vm.prank(writer);
        wrappedLong.unwrapLongs(8.000001e6);
    }

    /////////
    // function exerciseLongs(uint256 amount) external;

    // TODO

    /////////
    // ClarityWrappedShort

    // TODO
}
