// https://github.com/provable-things/ethereum-api

pragma solidity >= 0.5.0 < 0.6.0;

import "github.com/provable-things/ethereum-api/provableAPI.sol";

contract RandomExample is usingProvable {

  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint256 public latestNumber;
  bytes32 queryId;

  event LogNewProvableQuery(string description);
  event generatedRandomNumber(uint256 randomNumber);

  constructor()
  public
  {
    update();
  }

  // the external contract will always send its answer to a __callback() function
  // so we need to have a function named exactly this way to receive the response
  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    // Checks that the the callback function is called from the oracle-contract
    require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumer = randomNumber;
    emit generatedRandomNumber(randomNumber);
  }

  function update() payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    queryId = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY,
      NUM_RANDOM_BYTES_REQUESTED,
      GAS_FOR_CALLBACK
      );
      emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }


// The following "Test"-Functions are used to help during development, it saves time during testing
// because we dont need to wait for the answer of the oracle code
    function updateTest() payable public {
      uint256 QUERY_EXECUTION_DELAY = 0;
      uint256 GAS_FOR_CALLBACK = 200000;
      queryId = testRandom();
      emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
  }

  function testRandom() public returns (bytes32) {
    bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
    __callbackTest(queryId, "1", bytes("test"));
    return queryId;
  }

  function __callbackTest(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumer = randomNumber;
    emit generatedRandomNumber(randomNumber);
  }
