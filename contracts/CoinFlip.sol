import "./Ownable.sol";
import "./provableAPI.sol";
//pragma solidity 0.5.12;
pragma solidity >=0.4.21 <0.7.0;

contract Coinflip is Ownable, usingProvable {

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
  mapping(address => bytes32) private activePlayers;
  mapping(address => uint) private playerBalances;

  uint public balance;

  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  bytes32 queryId;

  function flip(bool bet) payable public {
    // check if contract has enough balance
    require(msg.value <= balance);
    // Prevent users draining the contract with 0 Ether bets (oracle gas costs)
    require(msg.value >= 0.1 ether);
//    // Players can only play one bet at a time
//    require(activePlayers[msg.sender] == 0);

    Bet memory newBet;
    newBet.heads = bet;
    newBet.stake = msg.value;
    newBet.player = msg.sender;

    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;

    queryId = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
    queue[queryId] = newBet;
    activePlayers[msg.sender] =  queryId;
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public override {
    // Checks that the the callback function is called from the oracle-contract
    require(msg.sender == provable_cbAddress());
    // Generate heads or tales; heads = true
    bool result = (uint256(keccak256(abi.encodePacked(_result))) % 2) != 0;

    if(result == queue[_queryId].heads){
      queue[_queryId].won = true;
      balance = balance - (queue[_queryId].stake);
      playerBalances[queue[_queryId].player] += (queue[_queryId].stake)*2;
    }
    else{
      queue[_queryId].won = false;
      balance = balance + (queue[_queryId].stake);
    }
    // emit result to frontend
    emit resultReady(queue[_queryId].player, queue[_queryId].won, playerBalances[queue[_queryId].player]);
    // clear player from mapping
    delete activePlayers[queue[_queryId].player];
    delete queue[_queryId];
  }

  function getBalance() public view returns (uint) {
    return balance;
  }

  function getPlayerBalance(address player) public view returns (uint) {
    return playerBalances[player];
  }

  function withdrawPlayer() public returns(uint) {
    uint toTransfer = playerBalances[msg.sender];
    playerBalances[msg.sender] = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
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

    function deposit() payable public{
      balance += msg.value;
    }
  }
