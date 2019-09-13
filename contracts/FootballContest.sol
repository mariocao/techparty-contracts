pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
import "./requests/FootballHome.sol";
import "./requests/FootballAway.sol";


contract FootballContest is UsingWitnet {
  using SafeMath for uint256;

  address owner;
  uint256 footballHomeRequestId;
  uint256 footballAwayRequestId;
  uint256 public grandPrice;
  int128 public actualHome;
  int128 public actualAway;
  bool public isResolved;
  mapping(uint8 => Contestant[]) public contestants;

  struct Contestant {
    address payable addr;
    uint256 amount;
  }

  constructor (address _wbi) UsingWitnet(_wbi) public {
    owner = msg.sender;
  }

  function initialize(uint256 _requestFee, uint256 _resultFee) public payable {
    require(msg.sender == owner, "You must be the owner to call initialize");
    require(footballHomeRequestId == 0, "Home request was already initialized");
    require(footballAwayRequestId == 0, "Away request was already initialized");

    Request footballHomeRequest = new FootballHomeRequest();
    footballHomeRequestId = witnetPostRequest(footballHomeRequest, _requestFee, _resultFee);

    Request footballAwayRequest = new FootballAwayRequest();
    footballAwayRequestId = witnetPostRequest(footballAwayRequest, _requestFee, _resultFee);
  }

  // Winner is defined as: 0 draw, 1 home, 2 away
  function participate(uint8 winner) public payable witnetRequestAccepted(footballHomeRequestId) witnetRequestAccepted(footballAwayRequestId){
    contestants[winner].push(Contestant(msg.sender, msg.value));
    grandPrice = grandPrice + msg.value;
  }

  function resolve() public {
    require(!isResolved, "The contest is already resovled");

    actualHome = witnetReadResult(footballHomeRequestId).asInt128();
    actualAway = witnetReadResult(footballAwayRequestId).asInt128();

    Contestant[] memory winners;
    if (actualHome == actualAway) {
      winners = contestants[0];
    } else if (actualHome - actualAway > 0) {
      winners = contestants[1];
    } else {
      winners = contestants[2];
    }

    if (winners.length == 0) {
      for (uint8 i = 0; i < 3; i++) {
        for (uint j = 0; j < contestants[i].length; j++) {
          Contestant memory contestant = contestants[i][j];
          contestant.addr.transfer(contestant.amount);
        }
      }
    }
    else {
      uint256 total_from_winners = 0;
      for (uint i = 0; i < winners.length; i++) {
        total_from_winners = total_from_winners + winners[i].amount;
      }

      uint256 prize_share = grandPrice / total_from_winners;
      for (uint i = 0; i < winners.length; i++) {
        Contestant memory winner = winners[i];
        uint256 prize = winner.amount * prize_share;
        winner.addr.transfer(prize);
      }
    }

    isResolved = true;
  }

  modifier before(uint256 _timestamp) {
    require(block.timestamp < _timestamp, "The participation window is over");
    _;
  }
}
