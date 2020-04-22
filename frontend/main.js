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
    contractInstance = new web3.eth.Contract(abi, "0xe5f11d7C22e781dCC432163e1491bA04d76530d0", {from: accounts[0]});
    console.log(contractInstance);
    address = accounts[0];
    getBalance();
    checkAdmin();
  });

  // click listener for Add Data Button
  $("#submit_bet_button").click(flip)
  // click listener for Get Data Button
  $("#fund_contract_button").click(fundContract)
  // click listener for Get Data Button
  $("#withdraw_funds_button").click(widthdrawFunds)
});

function flip(){
  $("#result").html("Good Luck!")
  var bet = false;
  var radioValue = $("input[name='heads-or-tales']:checked").val();
  if(radioValue){
    //alert("You picked - " + radioValue);
    if(radioValue=="heads"){
      bet = true;
    }
  }

  var val = $("#bet_input").val();
  var config = {
    value: web3.utils.toWei(val.toString(), "ether")
  }

  contractInstance.methods.flip(bet).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })

  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })

  .on("receipt", function(receipt){
    // if(receipt.status === "0x1"){
    // }else{ alert("Receipt status fail"); }
    console.log(receipt);
    getBalance();
    getResult();
  })
}


// TO DISPLAY VIA THE RESULT-ID ON FRONTEND IF WON OR LOST
function getResult(){
  contractInstance.methods.getLastFlip(address).call().then(function(result){
    console.log(result);
    if(result){
      $("#result").html("You won!");
    }
    else{
      $("#result").html("You lost!");
    }
  });
}

function getBalance() {
  contractInstance.methods.getBalance().call().then(function(result){
    result = web3.utils.fromWei(result, 'ether');
    console.log(result);
    $("#balance").html(result);
  });
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

  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })

  .on("receipt", function(receipt){
    // if(receipt.status === "0x1"){
    // }else{ alert("Receipt status fail"); }
    console.log(receipt);
    getBalance();
  })
}

function widthdrawFunds() {
  contractInstance.methods.withdrawAll().call().then(function(result){
    result = web3.utils.fromWei(result, 'ether');
    alert("Balance withdrawn!")
    console.log(result);
  })
}

function checkAdmin() {
  contractInstance.methods.checkAdmin().call().then(function(result){
    if(result){
      $("#admin").show();
      $("#ownerAddress_output").html(address);
      //alert("Hi Boss!")
    }
  })
}
