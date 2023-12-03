// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Script Helpers
import {Script, console2} from "forge-std/Script.sol";

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Test Contracts
import {MockERC20} from "../test/util/MockERC20.sol";

// Contracts
import {ClarityMarkets} from "../src/ClarityMarkets.sol";

// forge script ./script/DeployWithMocks.s.sol --broadcast --slow
// forge verify-contract WETH_ADDRESS ./test/util/MockERC20.sol:MockERC20 --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "WETH Like" "WETH" 18) --chain 84531 --watch
// forge verify-contract WBTC_ADDRESS ./test/util/MockERC20.sol:MockERC20 --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "WBTC Like" "WBTC" 8) --chain 84531 --watch
// forge verify-contract FRAX_ADDRESS ./test/util/MockERC20.sol:MockERC20 --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "FRAX Like" "FRAX" 18) --chain 84531 --watch
// forge verify-contract USDC_ADDRESS ./test/util/MockERC20.sol:MockERC20 --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "USDC Like" "USDC" 6) --chain 84531 --watch
// forge verify-contract DCP_ADDRESS ./src/ClarityMarkets.sol:ClarityMarkets --chain 84531 --watch

/// @dev This script deploys ClarityMarkets and 4 mock assets, then writes some
/// ETH and BTC options for testing (1 expiry * 5 strikes * call and put).
contract DeployWithMocksScript is Script {
    /////////

    // 👩‍💻 configure expiry and strikes
    uint32 private constant nextFriday = 1_702_040_400;
    uint256 private constant ethAtmStrike = 2200;
    uint256 private constant ethOptionChainIncrement = 100;
    uint256 private constant btcAtmStrike = 40_000;
    uint256 private constant btcOptionChainIncrement = 1000;

    function run() public {
        // 🔧 load env variables
        string memory rpc = vm.rpcUrl("base_goerli");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.envAddress("DEPLOYER_ADDRESS");
        bytes32 nacl = keccak256(abi.encodePacked(vm.envString("SALT")));

        vm.createSelectFork(rpc);
        vm.startBroadcast(pk);

        // 🤫 deploy mock assets
        MockERC20 WETHLIKE = new MockERC20{salt: nacl}("WETH Like", "WETH", 18);
        MockERC20 WBTCLIKE = new MockERC20{salt: nacl}("WBTC Like", "WBTC", 8);
        MockERC20 FRAXLIKE = new MockERC20{salt: nacl}("FRAX Like", "FRAX", 18);
        MockERC20 USDCLIKE = new MockERC20{salt: nacl}("USDC Like", "USDC", 6);

        // 💰 mint myself a million
        WETHLIKE.mint(me, 1e6 * 1e18);
        WBTCLIKE.mint(me, 1e6 * 1e8);
        FRAXLIKE.mint(me, 1e6 * 1e18);
        USDCLIKE.mint(me, 1e6 * 1e6);

        // 🏯 deploy the DCP
        ClarityMarkets clarity = new ClarityMarkets{salt: nacl}();

        // ✍️ write some options
        uint256[] memory ethStrikes = new uint256[](5);
        ethStrikes[0] = ethAtmStrike - (ethOptionChainIncrement * 2);
        ethStrikes[1] = ethAtmStrike - ethOptionChainIncrement;
        ethStrikes[2] = ethAtmStrike;
        ethStrikes[3] = ethAtmStrike + ethOptionChainIncrement;
        ethStrikes[4] = ethAtmStrike + (ethOptionChainIncrement * 2);
        uint256[] memory btcStrikes = new uint256[](5);
        btcStrikes[0] = btcAtmStrike - (btcOptionChainIncrement * 2);
        btcStrikes[1] = btcAtmStrike - btcOptionChainIncrement;
        btcStrikes[2] = btcAtmStrike;
        btcStrikes[3] = btcAtmStrike + btcOptionChainIncrement;
        btcStrikes[4] = btcAtmStrike + (btcOptionChainIncrement * 2);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        WBTCLIKE.approve(address(clarity), type(uint256).max);
        FRAXLIKE.approve(address(clarity), type(uint256).max);
        USDCLIKE.approve(address(clarity), type(uint256).max);
        for (uint256 i = 0; i < ethStrikes.length; i++) {
            clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: nextFriday,
                strike: ethStrikes[i] * 1e18, // FRAX decimals
                allowEarlyExercise: true,
                optionAmount: 1e6 // Clarity decimals
            });
            clarity.writeNewPut({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: nextFriday,
                strike: ethStrikes[i] * 1e18,
                allowEarlyExercise: true,
                optionAmount: 1e6
            });
            clarity.writeNewCall({
                baseAsset: address(WBTCLIKE),
                quoteAsset: address(USDCLIKE),
                expiry: nextFriday,
                strike: btcStrikes[i] * 1e6, // USDC decimals
                allowEarlyExercise: true,
                optionAmount: 1e6
            });
            clarity.writeNewPut({
                baseAsset: address(WBTCLIKE),
                quoteAsset: address(USDCLIKE),
                expiry: nextFriday,
                strike: btcStrikes[i] * 1e6,
                allowEarlyExercise: true,
                optionAmount: 1e6
            });
        }

        vm.stopBroadcast();
    }
}
