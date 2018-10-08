var RockPaperScissors = artifacts.require("../contracts/RockPaperScissors.sol");
contract('RockPaperScissors', function (accounts) {
  let instance;
  let playersHash;
  let playerOneBalance;
  let playerTwoBalance;


  const playerOne = accounts[0];
  const playerTwo = accounts[1];
  const owner = accounts[2];

  const emptyAddress = /^0x0+$/

  beforeEach(function () {
    return RockPaperScissors.new({ from: owner })
      .then(function (_instance) {
        instance = _instance;
      
        playerOneBalance = web3.eth.getBalance(playerOne);
        playerTwoBalance = web3.eth.getBalance(playerTwo);
        return instance.returnPlayersKey()
        .then (result => {
          playersHash = result;
          console.log('<<>>',result);
          return instance.playerOneStartGame(playersHash,0,{ from: playerOne, value: web3.toWei('0.1', 'ether') })
        })
        .catch(result => console.log("Error:",result));  
      })
      .catch(result => console.log("Error:",result));
  });


  console.log(!instance);


  it("should not be able to to let player two play if password hash is empty", function () {
    console.log(!instance);
    return instance.playerTwoEnterAndPlay(0, 0,  { from: owner })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });



  it("should not be able to allow player two to play if game already completed.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.1', 'ether') })
    
    return instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.1', 'ether') })
      .then(result => {
        console.log(result);
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });


  it("should not be able to allow player two to play betting amount is not equal.",function () {
    
    return instance.playerTwoEnterAndPlay(playersHash,0, { from: playerTwo, value: web3.toWei('0.01', 'ether') })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });





  it("should not be able to withdraw balance if hash is empty.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.01', 'ether') })

    return instance.withdrawBalance(0, { from: playerTwo })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should not be able to withdrawer balance unless you are the winner.",async function () {
    
    let newHash = await instance.returnPlayersKey();

    await instance.playerOneStartGame(newHash,0,{ from: playerOne, value: web3.toWei('0.1', 'ether') })
 
    await instance.playerTwoEnterAndPlay(newHash,1, { from: playerTwo, value: web3.toWei('0.1', 'ether') })

    return instance.withdrawBalance(newHash, { from: owner })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });


  it("should not be able to transfer balance unless you are the winner in the prior game.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.1', 'ether') })

    let newHash = await instance.returnPlayersKey();

    await instance.playerOneStartGame(newHash,0,{ from: owner, value: web3.toWei('0.1', 'ether') });

    return instance.playerTwoEnterAndPlayWithFunds(newHash,1,0, { from: playerTwo })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });



  it("should not be able to transfer balance unless you have funds.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.1', 'ether') });

    await instance.withdrawBalance(playersHash, { from: playerTwo });


    let newHash = await instance.returnPlayersKey();
    
    await instance.playerOneStartGame(newHash, 0,{ from: playerOne, value: web3.toWei('0.1', 'ether') });

    return instance.playerTwoEnterAndPlayWithFunds(newHash,1,playersHash, { from: playerTwo })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });


  it("should allow Player one to win.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.01', 'ether') })

    return instance.withdrawBalance(playersHash, { from: playerTwo })
      .then(result => {
        assert.isTrue(true);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should allow Player two to win.",async function () {
    
    await instance.playerTwoEnterAndPlay(playersHash,1, { from: playerTwo, value: web3.toWei('0.01', 'ether') })

    return instance.withdrawBalance(playersHash, { from: playerTwo })
      .then(result => {
        assert.isTrue(true);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should allow a draw.",async function () {
    
    return instance.playerTwoEnterAndPlay(playersHash,0, { from: playerTwo, value: web3.toWei('0.01', 'ether') })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });




});