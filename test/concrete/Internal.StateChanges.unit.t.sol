// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTestSuite.t.sol";

contract StateChangesTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;

    function test_stateChanges() public {
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        vm.record();
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 2050e18,
            allowEarlyExercise: true,
            optionAmount: 1e6
        });
        clarity.netOffsetting(optionTokenId, 0.5e6);
        clarity.exerciseOption(optionTokenId, 0.45e6);
        vm.warp(FRI1 + 1 seconds);
        clarity.redeemCollateral(optionTokenId.longToShort());
        vm.stopPrank();

        (, bytes32[] memory writes) = vm.accesses(address(clarity));

        (uint64 w, uint64 n, uint64 x, uint64 r) = getInternalOptionState(writes[5]);

        assertEq(w, 1e6);
        assertEq(n, 0.5e6);
        assertEq(x, 0.45e6);
        assertEq(r, 0.5e6);

        // console2.log("Amount written", w);
        // console2.log("Amount netted", n);
        // console2.log("Amount exercised", x);
        // console2.log("Amount redeemed", r);

        // console2.log(reads.length);
        // console2.log(writes.length);

        // for (uint256 i = 0; i < writes.length; i++) {
        //     console2.logBytes32(writes[i]);
        // }

        // bytes32 state = vm.load(
        //     address(clarity),
        //     0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb2
        // );
        // console2.log("State packed");
        // console2.logBytes32(state);

        // writeNewCall()
        // 1. Option Info and State
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb0
        // address writeAsset;
        // uint64 writeAmount;
        // OptionType optionType;
        // ExerciseStyle exerciseStyle;
        //
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb1
        // address exerciseAsset;
        // uint64 exerciseAmount;
        // uint32 expiry;
        //
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb2
        // OptionState optionState;
        //
        // 2. Shortened Ticker
        // 0xe8f58977c73b01eb27ffff969fe1227c62f817fe0a27a00b68d79a092e4aee73
        // 3. Base Asset Info
        // 0xa36e1c24ba79d81bb60bdfe6ae9bc204457dacfbf6329fc5a823be2c8b70bb40
        // 4. Quote Asset Info
        // 0xa3c8b8a4608eb61dca040724839500d762e10d5edf37f5e141dbd8bd59f6db2b
        // 5. Mint Longs
        // 0xb8b95d50487616eb7f989adf66efb8356a820a13599986065c18da7581105764
        // 6. Mint Shorts
        // 0x64e5819c9c7683c69044f7be8b67f199235a6f5963f834314e626da70c22eecb
        // 7. Increment Write Asset Clearing Liability
        // 0x4743af99d74bc9527f04d4a794f0718d207b154212be76625538e9a1aa8b8908
        //
        // (1. External -- Write Asset ERC20 Transfer)

        // netOff()
        // 1. Update Option State
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb2
        // 2. Burn Longs
        // 0xb8b95d50487616eb7f989adf66efb8356a820a13599986065c18da7581105764
        // 3. Burn Shorts
        // 0x64e5819c9c7683c69044f7be8b67f199235a6f5963f834314e626da70c22eecb
        // 4. Decrement Write Asset Clearing Liability
        //
        // (1. External -- Write Asset ERC20 Transfer)

        // exerciseOption()
        // 1. Update Option State
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb2
        // 2. Burn Longs
        // 0xb8b95d50487616eb7f989adf66efb8356a820a13599986065c18da7581105764
        // 3. Decrement Write Asset Clearing Liability
        // 0x4743af99d74bc9527f04d4a794f0718d207b154212be76625538e9a1aa8b8908
        // 4. Increment Exercise Asset Clearing Liability
        // 0x6bce9b592bcd9632b463383792a5ec3de1f8ec3cf8b2cd967d5e59ac275b6b4b
        //
        // (1. External -- Exercise Asset ERC20 Transfer)
        // (2. External -- Write Asset ERC20 Transfer)

        // redeemCollateral()
        // 1. Burn Shorts
        // 0x64e5819c9c7683c69044f7be8b67f199235a6f5963f834314e626da70c22eecb
        // 2. Update Option State
        // 0x35e50ad5316a07f423998518dec1bf9bff6be39bc580c77622ff4b474a489eb2
        // 3. Decrement Write Asset Clearing Liability
        // 0x4743af99d74bc9527f04d4a794f0718d207b154212be76625538e9a1aa8b8908
        // 4. Increment Exercise Asset Clearing Liability
        // 0x6bce9b592bcd9632b463383792a5ec3de1f8ec3cf8b2cd967d5e59ac275b6b4b
        //
        // (1. External -- Exercise Asset ERC20 Transfer)
        // (2. External -- Write Asset ERC20 Transfer)
    }
}
