// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.23;

// // Test Harness
// import "../BaseUnitTestSuite.t.sol";

// // Libraries
// import {LibOption} from "../../src/library/LibOption.sol";
// import {LibPosition} from "../../src/library/LibPosition.sol";

// // Views Under Test
// import {IOption} from "../../src/interface/option/IOption.sol";

// contract OptionViewTest is BaseUnitTestSuite {
//     /////////

//     using LibOption for uint32[];

//     using LibPosition for uint248;
//     using LibPosition for uint256;

//     /////////
//     // function optionTokenId(
//     //     address baseAsset,
//     //     address quoteAsset,
//     //     uint32[] calldata exerciseWindows,
//     //     uint256 strike,
//     //     bool isCall
//     // ) external view returns (uint256 optionTokenId);

//     function test_optionTokenId_whenCall_andAmerican() public {
//         vm.startPrank(writer);
//         WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
//         uint256 expectedOptionTokenId = clarity.writeNewCall({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         uint256 actualOptionTokenId = clarity.optionTokenId({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             isCall: true
//         });

//         assertEq(actualOptionTokenId, expectedOptionTokenId);
//     }

//     function test_optionTokenId_whenPut_andAmerican() public {
//         vm.startPrank(writer);
//         FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
//         uint256 expectedOptionTokenId = clarity.writeNewPut({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         uint256 actualOptionTokenId = clarity.optionTokenId({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             isCall: false
//         });

//         assertEq(actualOptionTokenId, expectedOptionTokenId);
//     }

//     function test_optionTokenId_whenCall_andEuropean() public {
//         vm.startPrank(writer);
//         WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
//         uint256 expectedOptionTokenId = clarity.writeNewCall({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         uint256 actualOptionTokenId = clarity.optionTokenId({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             isCall: true
//         });

//         assertEq(actualOptionTokenId, expectedOptionTokenId);
//     }

//     function test_optionTokenId_whenPut_andEuropean() public {
//         vm.startPrank(writer);
//         FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
//         uint256 expectedOptionTokenId = clarity.writeNewPut({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         uint256 actualOptionTokenId = clarity.optionTokenId({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             isCall: false
//         });

//         assertEq(actualOptionTokenId, expectedOptionTokenId);
//     }

//     // Sad Paths

//     function testRevert_optionTokenId_whenOptionDoesNotExist() public {
//         uint256 optionTokenId = LibOption.paramsToHash({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionType: IOption.OptionType.CALL
//         }).hashToId();

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IOptionErrors.OptionDoesNotExist.selector, optionTokenId
//             )
//         );

//         clarity.optionTokenId({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             isCall: true
//         });
//     }

//     /////////
//     // function option(uint256 optionTokenId) external view returns (Option memory
//     // option);

//     function test_option_whenCall_andAmerican() public {
//         vm.startPrank(writer);
//         WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
//         uint256 optionTokenId = clarity.writeNewCall({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         IOption.Option memory expectedOption = IOption.Option({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0].toExerciseWindow(),
//             strike: 1950e18,
//             optionType: IOption.OptionType.CALL,
//             exerciseStyle: IOption.ExerciseStyle.AMERICAN
//         });

//         assertEq(clarity.option(optionTokenId), expectedOption);
//     }

//     function test_option_whenPut_andAmerican() public {
//         vm.startPrank(writer);
//         FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
//         uint256 optionTokenId = clarity.writeNewPut({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         IOption.Option memory expectedOption = IOption.Option({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0].toExerciseWindow(),
//             strike: 1950e18,
//             optionType: IOption.OptionType.PUT,
//             exerciseStyle: IOption.ExerciseStyle.AMERICAN
//         });

//         assertEq(clarity.option(optionTokenId), expectedOption);
//     }

//     function test_option_whenCall_andEuropean() public {
//         vm.startPrank(writer);
//         WETHLIKE.approve(address(clarity), scaleUpAssetAmount(WETHLIKE, STARTING_BALANCE));
//         uint256 optionTokenId = clarity.writeNewCall({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         IOption.Option memory expectedOption = IOption.Option({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0].toExerciseWindow(),
//             strike: 1950e18,
//             optionType: IOption.OptionType.CALL,
//             exerciseStyle: IOption.ExerciseStyle.EUROPEAN
//         });

//         assertEq(clarity.option(optionTokenId), expectedOption);
//     }

//     function test_option_whenPut_andEuropean() public {
//         vm.startPrank(writer);
//         FRAXLIKE.approve(address(clarity), scaleUpAssetAmount(FRAXLIKE, STARTING_BALANCE));
//         uint256 optionTokenId = clarity.writeNewPut({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0],
//             strike: 1950e18,
//             optionAmount: 1e6
//         });
//         vm.stopPrank();

//         IOption.Option memory expectedOption = IOption.Option({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: europeanExWeeklies[0].toExerciseWindow(),
//             strike: 1950e18,
//             optionType: IOption.OptionType.PUT,
//             exerciseStyle: IOption.ExerciseStyle.EUROPEAN
//         });

//         assertEq(clarity.option(optionTokenId), expectedOption);
//     }

//     // Sad Paths

//     function testRevert_option_whenOptionDoesNotExist() public {
//         uint256 optionTokenId = LibOption.paramsToHash({
//             baseAsset: address(WETHLIKE),
//             quoteAsset: address(FRAXLIKE),
//             expiry: expiryWeeklies[0],
//             strike: 1950e18,
//             optionType: IOption.OptionType.CALL
//         }).hashToId();

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IOptionErrors.OptionDoesNotExist.selector, optionTokenId
//             )
//         );

//         clarity.option(optionTokenId);
//     }
// }
