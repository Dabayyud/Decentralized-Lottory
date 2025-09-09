// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/MockFilesLocalDeployment/LinkToken.sol";

abstract contract CodeConstant {
    int256 public MOCK_WEI_PER_UNIT_LINK = 2e15;
    int96 public MOCK_BASE_FEE = 0.05 ether;
    int96 public MOCK_GAS_PRICE_LINK = 1e8;
    uint256 public constant SepoliaChainId = 11155111;
    uint256 public constant MainnetChainId = 1;
    uint256 public constant LocalHostChainId = 31337;
}

contract HelperConfig is CodeConstant, Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;

    struct NetworkConfig {
        uint256 ticketPrice;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainID => NetworkConfig) public networkConfig;

    constructor() {
        activeNetworkConfig = getActiveNetworkConfig();
    }

    function getActiveNetworkConfig() public returns (NetworkConfig memory) {
        if (block.chainid == SepoliaChainId) {
            return getSepoliaEthConfig();
        } else if (block.chainid == MainnetChainId) {
            return getMainnetEthConfig();
        } else {
            return getLocalHostEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 54993270142118822777529067368690737207554838296906475770118486147637112141146,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            keyHash: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
            subId: 0,
            callbackGasLimit: 500000,
            link: (address(0))
        });
    }

    function getLocalHostEthConfig() public returns (NetworkConfig memory) {
        if (networkConfig[CodeConstant.LocalHostChainId].vrfCoordinator != address(0)) {
            return networkConfig[CodeConstant.LocalHostChainId];
        }
        // Deploy Mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator =
            new VRFCoordinatorV2_5Mock(uint96(MOCK_BASE_FEE), uint96(MOCK_GAS_PRICE_LINK), MOCK_WEI_PER_UNIT_LINK);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            keyHash: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            subId: 0,
            callbackGasLimit: 500000,
            link: address(link)
        });
    }
}
