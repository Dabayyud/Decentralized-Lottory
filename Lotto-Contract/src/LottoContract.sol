// SPDX-License-Identifier: MIT

// Layout of contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// state variables
// events
// modifiers
// functions

// Layout of functions:
// constructor
// receive functions (if exists)
// fallback functions (if exists)
// external
// public
// internal
// private
// view / pure

pragma solidity ^0.8.19;

// imports:
import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

//
 // @title Lotto Contract
 // @author Ayyub
 // @notice This contract implements a lottery system.

contract LottoContract is VRFConsumerBaseV2Plus {
    // Type declarations:
    enum LottoState {
        OPEN,
        CALCULATING
    }

    // state variables:
    uint256 public immutable i_ticketPrice;
    uint256 public immutable i_interval; // How often the lottery should run in seconds
    address public immutable i_vrfCoordinator;
    bytes32 public immutable i_keyHash;
    uint256 public immutable i_subId;
    uint32 public immutable i_callbackGasLimit;

    uint16 public constant REQUEST_CONFIRMATIONS = 3; // The default is 3, but you can set this higher. // The default is 100000, but you can set this higher.
    uint32 public constant NUM_WORDS = 1;

    address payable[] public s_players; // s indicates storage
    address private s_recentWinner;

    uint256 private s_lastTimeStamp; // last time a winner was picked
    LottoState private s_lottoState;

    // Events:
    event requestedLottoWinner(uint256 indexed requestId);
    event LottoEnter(address indexed player);
    event Winner(address indexed player);

    // errors:
    error LottoContract__SendMoreToEnter(); // Use a small prefix for error names to clarify which contract they belong to
    error LottoContract__TransferFailed();
    error LottoContract__NotOpen();
    error LottoContract__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lottoState);

    constructor(
        uint256 ticketPrice,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_ticketPrice = ticketPrice;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = vrfCoordinator;
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;

        s_lottoState = LottoState.OPEN; // or LottoState(0)

        // VRF request should be made using VRFConsumerBaseV2Plus's requestRandomWords with correct arguments when needed, not in constructor.
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeCheck = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = (s_lottoState == LottoState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeCheck && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "");
    }

    function enterLotto() public payable {
        if (msg.value < i_ticketPrice) {
            revert LottoContract__SendMoreToEnter();
        }
        if (s_lottoState != LottoState.OPEN) {
            revert LottoContract__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LottoEnter(msg.sender);
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        // Check to see if enough time has passed
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert LottoContract__UpkeepNotNeeded(
                address(this).balance, uint256(s_players.length), uint256(s_lottoState)
            );
        }
        s_lottoState = LottoState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        // make request to the chainlink VRF coordinator
        emit requestedLottoWinner(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // CHECKS (CONDITIONALS)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        // EFFECTS (INTERNAL CONTRACT STATE)
        // Reset
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_lottoState = LottoState.OPEN;
        emit Winner(s_recentWinner);

        // INTERACTIONS (EXTERNAL CONTRACT CALLS)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert LottoContract__TransferFailed();
        }
    }
    // getter functions

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getTicketPrice() external view returns (uint256) {
        return i_ticketPrice;
    }

    function getLottoState() external view returns (LottoState) {
        return s_lottoState;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getDeployedLotto() external view returns (address) {
        return address(this);
    }
}
