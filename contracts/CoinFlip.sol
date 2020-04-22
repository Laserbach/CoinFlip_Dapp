import "./Ownable.sol";
pragma solidity 0.5.12;

contract Coinflip is Ownable {

    mapping(address => bool) lastFlip;

    uint public balance;

    function flip(bool bet) payable public {
        // check if contract has enough balance
        require((msg.value)*2 <= balance);
        // Generate heads or tales; heads = true
        bool coin = (now%2) != 0;
        // determin win or lose
        if(coin == bet){
            balance = balance - (msg.value);
            msg.sender.transfer((msg.value)*2);
            lastFlip[msg.sender]=true;
        }
        else{
            balance = balance + msg.value;
            lastFlip[msg.sender]=false;
        }
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function getLastFlip(address player) public view returns (bool) {
        return lastFlip[player];
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

    function checkAdmin() public returns(bool){
      if(owner==msg.sender){
        return true;
      } else { return false; }
    }
}
