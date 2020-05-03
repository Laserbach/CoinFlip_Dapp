var web3 = new Web3(Web3.givenProvider);
var contractInstance
var address

$(document).ready(function() {
  $("#admin").hide();
  // request permission from the webpage to the metamask account to interact with it
  // Needs to be approved by the user (prompt appears
  window.ethereum.enable().then(function(accounts){
    // The function is asynchronous and we want to make use of the accounts-array
    // which gets returned

    // abi is similiar to a header file
    contractInstance = new web3.eth.Contract(abi, "0x9f0A3E669Ef37C95Fbbb8dC8B8c6ef2F643498E4", {from: accounts[0]});
    console.log(contractInstance);
    address = accounts[0];
    getBalance();
    getPlayerBalance();
    checkAdmin();

    // event listener
    contractInstance.events.resultReady({},function(error, event) {
      if (error){
        console.error(error);
      }
      let playerAdress = event.returnValues.player;
      let won = event.returnValues.won;
      let playerBalance = web3.utils.fromWei(event.returnValues.playerBalance, 'ether');

      console.log(playerAdress);
      console.log(won);
      console.log(playerBalance);
      console.log(event);
      console.log(event.returnValues)

      // shows all smart contract activity
      if(won){
        $('#loging').focus();
        $('#loging').html($('#loging').val()+'\n'+'Player '+playerAdress.toString()+' has won!'+'\n'+'----------$$$----------');
        $('#loging').scrollTop($('#loging')[0].scrollHeight);
      } else {
        $('#loging').focus();
        $('#loging').html($('#loging').val()+'\n'+'Player '+playerAdress.toString()+' has lost!'+'\n'+'----------$$$----------');
        $('#loging').scrollTop($('#loging')[0].scrollHeight);
      }

      // for the specific player
      if(playerAdress==address){
        if(won){
          $("#result").html("You won!");
          $("#playerBalance").html(playerBalance);
        }
        else{
          $("#result").html("You lost!");
          $("#playerBalance").html(playerBalance);
        }
      }
      getBalance();
    });
  });

  // click listeners
  $("#submit_bet_button").click(flip)
  $("#fund_contract_button").click(fundContract)
  $("#withdraw_funds_button").click(widthdrawFunds)
  $("#withdraw_winnings").click(widthdrawWinnings)

  //  Listening for Selected Account Changes
  setInterval(async function() {
    const accounts = await web3.eth.getAccounts();
    if (accounts[0] !== address) {
      address = accounts[0];
      checkAdmin();
      getPlayerBalance();
      $("#result").html("");
    }
  }, 100);
});

function flip(){
  if($("#bet_input").val() < 0.1){
    alert("Minimum Bet Amount is 0.1 ETH");
    return;
  }
  $("#result").html("Good Luck!")
  var bet = false;
  var radioValue = $("input[name='heads-or-tales']:checked").val();
  if(radioValue){
    if(radioValue=="heads"){
      bet = true;
    }
  }

  var val = $("#bet_input").val();
  var config = {
    from: address,
    value: web3.utils.toWei(val.toString(), "ether")
  }

  contractInstance.methods.flip(bet).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })

//  .on("confirmation", function(confirmationNr){
//    console.log(confirmationNr);
//  })

  .on("receipt", function(receipt){
    console.log(receipt);
    $("#result").html("Asking the almighty Oracle ...")
  })
}

function fundContract() {
  var val = $("#funding_input").val();
  var config = {
    value: web3.utils.toWei(val.toString(), "ether")
  }
  contractInstance.methods.deposit().send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })

//  .on("confirmation", function(confirmationNr){
//    console.log(confirmationNr);
//  })

  .on("receipt", function(receipt){
    // if(receipt.status === "0x1"){
    // }else{ alert("Receipt status fail"); }
    console.log(receipt);
    getBalance();
  })
}

function getBalance() {
  contractInstance.methods.getBalance().call().then(function(result){
    var amount = web3.utils.fromWei(result, 'ether');
    $("#balance").html(amount);
  });
}

function getPlayerBalance() {
  contractInstance.methods.getPlayerBalance(address).call().then(function(result){
    var amount = web3.utils.fromWei(result, 'ether');
    $("#playerBalance").html(amount);
  });
}

function widthdrawFunds() {
  contractInstance.methods.withdrawAll().send({from: address}).then(function(result){
    var amount = web3.utils.fromWei(result, 'ether');
    alert("Balance withdrawn!")
    console.log(amount);
    getBalance();
  })
}

function widthdrawWinnings() {
  contractInstance.methods.withdrawPlayer().send({from: address}).then(function(result){
    var amount = web3.utils.fromWei(result, 'ether');
    alert("Here is your reward!")
    console.log(amount);
    getPlayerBalance();
  })
}

// Important! By default web3 calls the contract functions from account[0]
// if you want that the frontend realises when you switched accounts, you need to pass the speciifc address in the function call
function checkAdmin() {
  contractInstance.methods.checkAdmin().call({from: address}).then(function(result){
    if(result){
      $("#admin").show();
      $("#ownerAddress_output").html(address);
      //alert("Hi Boss!")
    } else {
      $("#admin").hide();
    }
  })
}
