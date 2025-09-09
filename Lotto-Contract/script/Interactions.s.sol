// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstant} from "./HelperConfigLotto.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/MockFilesLocalDeployment/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract createSubscription is Script {
    function createNewSubscription() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        return createVrfSubscription(vrfCoordinator);
    }

    function createVrfSubscription(address vrfCoordinator) public returns (uint256, address) {
        vm.startBroadcast();
        console.log("Creating subscription on VRF Coordinator:", vrfCoordinator);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is:", subId);
        console.log("Please update the subscriptionId in the HelperConfig.s.sol file and re-deploy the contract");
        return (subId, vrfCoordinator);
    }

    function run() external {
        createNewSubscription();
    }
}

contract FundSubscription is Script, CodeConstant {
    uint256 constant FUND_AMOUNT = 100 ether;

    function fundVrfSubscription() public {
        HelperConfig helperConfig = new HelperConfig();
        address _vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 _subId = helperConfig.getActiveNetworkConfig().subId;
        address _linkToken = helperConfig.getActiveNetworkConfig().link;
        fundSubscription(_vrfCoordinator, _subId, _linkToken);
    }

    function fundSubscription (address vrfCoordinator, uint256 subId, address linkToken) public {
        console.log("Funding subscription on VRF Coordinator:", vrfCoordinator);
        console.log("Using Link token at:", linkToken);
        console.log("Funding with %s LINK", FUND_AMOUNT / 1e18);

        if (block.chainid == LocalHostChainId) {
            vm.startBroadcast();
            console.log("Local network detected! Funding with mocks...");
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, (FUND_AMOUNT * 1000));
            console.log("Subscription funded!");
            vm.stopBroadcast();

        }
        else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            console.log("Subscription funded!");
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {

    function addConsumerToSubscription() public {
        HelperConfig helperConfig = new HelperConfig();
        address _vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 _subId = helperConfig.getActiveNetworkConfig().subId;
        address _linkToken = helperConfig.getActiveNetworkConfig().link;
        address _lottoContract = DevOpsTools.get_most_recent_deployment("LottoContract", block.chainid);
        addConsumerToVrfSubscription(_vrfCoordinator, _subId, _lottoContract);
    }

    function addConsumerToVrfSubscription(address vrfCoordinator, uint256 subId, address consumer) public {
        vm.startBroadcast();
        console.log("Adding consumer to subscription...");
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
        console.log("Consumer added!");
        vm.stopBroadcast();
    }


    function run() external {
        addConsumerToSubscription();
    }
}
