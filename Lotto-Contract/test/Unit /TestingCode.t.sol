// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployLotto} from "../../script/DeployScriptLotto.s.sol";
import {LottoContract} from "../../src/LottoContract.sol";
import {HelperConfig} from "../../script/HelperConfigLotto.s.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract LottoContractTest is Test {
    event LottoEnter(address indexed player);
    event Winner(address indexed player);
    VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock;

    // Duplicate declaration removed: address public immutable PLAYER2 = makeAddr("player2");
    // Duplicate declaration removed: address public immutable PLAYER3 = makeAddr("player3");

    uint256 ticketPrice;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint256 subId;

    address public immutable PLAYER = makeAddr("player");
    address public immutable PLAYER2 = makeAddr("player2");
    address public immutable PLAYER3 = makeAddr("player3");
    uint256 public immutable STARTING_BALANCE = 10 ether;

    LottoContract public lotto;
    HelperConfig public helperConfig;

    function setUp() public {
    // Deploy mocks and config ONCE, reuse addresses
    helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
    ticketPrice = networkConfig.ticketPrice;
    interval = networkConfig.interval;
    vrfCoordinator = networkConfig.vrfCoordinator;
    keyHash = networkConfig.keyHash;
    callbackGasLimit = networkConfig.callbackGasLimit;
    // Use the deployed mock instance
    vrfCoordinatorV2_5Mock = VRFCoordinatorV2_5Mock(vrfCoordinator);
    // Create subscription and fund it
    subId = vrfCoordinatorV2_5Mock.createSubscription();
    vrfCoordinatorV2_5Mock.fundSubscription(subId, 2 ether);
    // Deploy LottoContract using the same config and correct subId
    lotto = new LottoContract(ticketPrice, interval, vrfCoordinator, keyHash, subId, callbackGasLimit);
    vrfCoordinatorV2_5Mock.addConsumer(subId, address(lotto));
    vm.deal(PLAYER, STARTING_BALANCE);
    vm.deal(PLAYER2, STARTING_BALANCE);
    vm.deal(PLAYER3, STARTING_BALANCE);
    }

    // Register Lotto contract as a consumer for the VRF subscription

    function testIfConstructorSetsVariablesCorrectly() public {
        assert(lotto.getTicketPrice() == ticketPrice);
        assert(lotto.getInterval() == interval);
        assert(lotto.getLottoState() == LottoContract.LottoState.OPEN);
    }

    function testConstructorSetsVariables() public {

        assertEq(lotto.i_ticketPrice(), ticketPrice);
        assertEq(lotto.i_interval(), interval);
        assertEq(lotto.i_vrfCoordinator(), vrfCoordinator);
        assertEq(lotto.i_keyHash(), keyHash);
        assertEq(lotto.i_subId(), subId);
        assertEq(lotto.i_callbackGasLimit(), callbackGasLimit);
    }

    function testIfLottoIsOpenUponDeployment() public {
        assert(lotto.getLottoState() == LottoContract.LottoState.OPEN);
    }

    function testGetTicketPrice() public view {
        uint256 price = lotto.getTicketPrice();
        assert(price == ticketPrice);
    }

    function testGetInterval() public view {
        uint256 intervalTime = lotto.getInterval();
        assert(intervalTime == interval);
    }

    function testGetNumberofPlayers() public {
        uint256 numPlayers = lotto.getNumberOfPlayers();
        assert(numPlayers == 0);
    }

    function testGetRecentWinner() public {
        address recentWinner = lotto.getRecentWinner();
        assert(recentWinner == address(0));
    }

    function testIfLottoRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(LottoContract.LottoContract__SendMoreToEnter.selector);
        lotto.enterLotto{value: ticketPrice - 1}();
    }

    function testIfLottoWorksWhenYouPayEnough() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        address player = lotto.s_players(0);
        assert(player == PLAYER);
    }

    function testIfLottoIsCalculatingWhenUpkeepIsNeeded() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = lotto.checkUpkeep("");
        assert(upkeepNeeded == true);
    }

    function testIfLottoIsNotCalculatingWhenUpkeepIsNotNeeded() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = lotto.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testIfRandomNumberCanBeRequested() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = lotto.checkUpkeep("");
        assert(upkeepNeeded == true);
    }

    function testIfEmittingEventsWork() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(lotto));
        emit LottoEnter(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
    }

    function testMultiplePlayersCanEnter() public {
        address lottoAddress = lotto.getDeployedLotto(); // Replace with your setup
        address player1 = address(0x1);
        address player2 = address(0x2);
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.prank(player1);
        lotto.enterLotto{value: lotto.i_ticketPrice()}();
        vm.prank(player2);
        lotto.enterLotto{value: lotto.i_ticketPrice()}();
        assertEq(lotto.getNumberOfPlayers(), 2);
    }

    function testNotAllowedToEnterWhileLottoIsCalculating() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lotto.performUpkeep("");
        vm.expectRevert(LottoContract.LottoContract__NotOpen.selector);
        vm.prank(PLAYER2);
        lotto.enterLotto{value: ticketPrice}();
    }
    
    function testCanHaveMultiplePlayersEnterLotto() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.prank(PLAYER2);
        lotto.enterLotto{value: ticketPrice}();
        vm.prank(PLAYER3);
        lotto.enterLotto{value: ticketPrice}();
        address player1 = lotto.s_players(0);
        address player2 = lotto.s_players(1);
        address player3 = lotto.s_players(2);
        assert(player1 == PLAYER);
        assert(player2 == PLAYER2);
        assert(player3 == PLAYER3);
    }

    function testIfPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lotto.performUpkeep("");
        assert(lotto.getLottoState() == LottoContract.LottoState.CALCULATING);
    }

    function testCheckUpkeepReturnsFalseIfThereIsNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Withdraw all funds to simulate no balance
        (bool upkeepNeeded,) = lotto.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testGetLastTimeStamp() public view {
        uint256 lastTimeStamp = lotto.getLastTimeStamp();
        assert(lastTimeStamp == block.timestamp);
    }

    function testGetterFunctions() public {
    address lottoAddress = lotto.getDeployedLotto(); // Replace with your setup
    // Enter lottery
    vm.deal(address(this), 1 ether);
    lotto.enterLotto{value: lotto.i_ticketPrice()}();
    assertEq(lotto.getNumberOfPlayers(), 1);
    // Should be zero address before winner picked
    assertEq(lotto.getRecentWinner(), address(0));

    }

    function testUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = lotto.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testLottoUpkeepNotNeededErrorRevertsProperly() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        LottoContract.LottoState lottoState = lotto.getLottoState();

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                LottoContract.LottoContract__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                uint256(lottoState)
            )
        );
        lotto.performUpkeep("");

    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public LottoEntered {

        vm.recordLogs(); // Record logs to capture the event
        lotto.performUpkeep(""); // This should emit the requestedLottoWinner event
        Vm.Log[] memory entries = vm.getRecordedLogs(); // Get the recorded logs
        bytes32 requestID = entries[1].topics[1]; // The requestId is the second topic in the second log
        // Assert
        LottoContract.LottoState lottoState = lotto.getLottoState();
        assert(uint256(lottoState) == 1);
        assert(uint256(requestID) > 0);
    }

    function testIfFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestID) public LottoEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestID, address(lotto));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public LottoEntered {
        // Arrange 
        uint256 additionalEntrants = 3; // 4 people total
        uint256 startingIndex = 1;

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            // Each player enters the lottery
            address player = address(uint160(i));
            hoax(player, 1 ether);
            lotto.enterLotto{value: ticketPrice}();
        }

        uint256 startingTimeStamp = lotto.getLastTimeStamp();
        address expectedWinner = address(1); // This is deterministic based on the mock's random number generation
        uint256 winnerBalance = expectedWinner.balance;

        // Act
        vm.recordLogs(); // Record logs to capture the event
        lotto.performUpkeep(""); // This should emit the requestedLottoWinner event
        Vm.Log[] memory entries = vm.getRecordedLogs(); // Get the recorded logs
        bytes32 requestID = entries[1].topics[1]; // The requestId is the second topic in the second log
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestID), address(lotto));

        // Assert
        address recentWinner = lotto.getRecentWinner();
        LottoContract.LottoState lottoState = lotto.getLottoState();
        uint256 endingTimeStamp = lotto.getLastTimeStamp();
        uint256 numPlayers = lotto.getNumberOfPlayers();
        uint256 winnerEndingBalance = recentWinner.balance;

        assert(recentWinner == expectedWinner);
        assert(uint256(lottoState) == 0);
        assert(endingTimeStamp > startingTimeStamp);
        assert(numPlayers == 0);
        assert(winnerEndingBalance == winnerBalance + (ticketPrice * (additionalEntrants + 1)));
    }
        

    modifier LottoEntered() {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        _;
    }

}