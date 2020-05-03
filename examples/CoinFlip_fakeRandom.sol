import "./Ownable.sol";
//import "./provableAPI.sol";
pragma solidity 0.5.12;

contract Coinflip is Ownable { //usingProvable

  event resultReady(address player, bool won, uint playerBalance);

  struct Bet {
    // betting heads (true) or tales (false)
    bool heads;
    // result of last coin-flip
    bool won;
    uint stake;
    address player;
  }

  mapping(bytes32 => Bet) private queue;
  mapping(address => uint) private playerBalances;

  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

  uint public balance;

  uint private queryIdFaker = 1;
  uint private randomNumberFaker = 1;

  function flip(bool bet) payable public {
    // check if contract has enough balance
    require((msg.value)*2 <= balance);
    // Prevent users draining the contract with 0 Ether bets (oracle gas costs)
    require(msg.value >= 0.1 ether);

    Bet memory newBet;
    newBet.heads = bet;
    newBet.stake = msg.value;
    newBet.player = msg.sender;

    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;

    bytes32 queryId = testRandom();
    queue[queryId] = newBet;
    __callbackTest(queryId, "1", bytes("test"));
  }

  function testRandom() private returns (bytes32) {
    bytes32 queryId = bytes32(keccak256(abi.encodePacked(queryIdFaker)));
    queryIdFaker += 1;
    return queryId;
  }

  function __callbackTest(bytes32 _queryId, string memory _result, bytes memory _proof) private {
    // Generate heads or tales; heads = true
    bool result = (randomNumberFaker % 2) != 0;
    randomNumberFaker += 1;

    if(result == queue[_queryId].heads){
      queue[_queryId].won = true;
      balance = balance - (queue[_queryId].stake);
      playerBalances[queue[_queryId].player] += queue[_queryId].stake;
    }
    else{
      queue[_queryId].won = false;
      balance = balance + (queue[_queryId].stake);
    }

    emit resultReady(queue[_queryId].player, queue[_queryId].won, playerBalances[queue[_queryId].player]);
  }

  function getBalance() public view returns (uint) {
    return balance;
  }

  function getPlayerBalance(address player) public view returns (uint) {
    return playerBalances[player];
  }

  function withdrawPlayer() public returns() {
    uint toTransfer = playerBalances[msg.sender];
    playerBalances[msg.sender] = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }

  function deposit() payable public{
    balance += msg.value;
  }

  function withdrawAll() public onlyOwner returns(uint) {
    uint toTransfer = balance;
    balance = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }

  function checkAdmin() public view returns(bool){
    if(owner==msg.sender){
      return true;
      } else { return false; }
    }
  }
