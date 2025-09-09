// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {LottoContract} from "../src/LottoContract.sol";
import {HelperConfig} from "../script/HelperConfigLotto.s.sol";
import {createSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployLotto is Script {

    function run() public {
        createSubscription createSub = new createSubscription();
        createSub.createNewSubscription();
        deployLottoContract();
    }

    function deployLottoContract() public returns (LottoContract, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();

        if (networkConfig.subId == 0) {
            createSubscription createSub = new createSubscription();
            (uint256 subId, address vrfCoordinator) = createSub.createNewSubscription();
            networkConfig.subId = subId;
            networkConfig.vrfCoordinator = vrfCoordinator;
        }

        vm.startBroadcast();
        LottoContract lottoContract = new LottoContract(
            networkConfig.ticketPrice,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.keyHash,
            networkConfig.subId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();
        FundSubscription fundSub = new FundSubscription();
        fundSub.fundVrfSubscription();
        AddConsumer addCons = new AddConsumer();
        addCons.addConsumerToVrfSubscription(address(lottoContract), networkConfig.subId, networkConfig.vrfCoordinator);

        return (lottoContract, helperConfig);
    }
}
