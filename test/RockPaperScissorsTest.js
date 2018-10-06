var RockPaperScissors = artifacts.require("../contracts/RockPaperScissors.sol");
contract('RockPaperScissors', function (accounts) {
  let instance;
  let playerHash;
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
        console.log(!instance);
        playerOneBalance = web3.eth.getBalance(playerOne);
        playerTwoBalance = web3.eth.getBalance(playerTwo);
        return instance.returnPlayersKey(playerOne, playerTwo)
        .then(result => {
          console.log(!instance);
          playerHash = result;
          console.log(!instance);
        })
        .catch(result => console.log("Error:",result));  
      })
      .catch(result => console.log("Error:",result));
  });


  console.log(!instance);

  it("should not be able to get password hash if password hashes is empty", function () {
    console.log(!instance);
    return instance.returnPlayersKey(0, 0,  { from: owner })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should not be able to add to player one balance if password hash is empty", function () {
    return instance.addToPlayerOneBalance(0,   { from: playerOne, value: web3.toWei('0.1', 'ether') })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should not be able to add to player two balance if password hash is empty", function () {
    return instance.addToPlayerTwoBalance(0,   { from: playerTwo, value: web3.toWei('0.1', 'ether') })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
        console.log(result);
        assert.isTrue(true);
      })
  });

  it("should not be able to add Player One move if password hash is empty", function () {
    return instance.addPlayerOneMove(0, 0,  { from: owner })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
          console.log(result);
        assert.isTrue(true);
      })
  });



  it("should not be able to add Player Two move if password hash is empty", function () {
    return instance.addPlayerTwoMove(0, 0,  { from: owner })
      .then(result => {
        assert.isTrue(false);
      })
      .catch(result => {
          console.log(result);
        assert.isTrue(true);
      })
  });

  it("should not be able to add Player One move if it is not a player", function () {
    return instance.addToPlayerOneBalance(playerHash, {from:playerOne})
    .then (result => {
        return instance.addPlayerOneMove(playerHash, 0,  { from: owner })
          .then(result => {
            assert.isTrue(false);
          })
          .catch(result => {
              console.log(result);
            assert.isTrue(true);
          })
        });
  });

  

  it("should not be able to add Player Two move if it is not a player", function () {
    return instance.addToPlayerTwoBalance(playerHash, {from:playerOne})
    .then (result => {
        return instance.addPlayerTwoMove(playerHash, 0,  { from: owner })
          .then(result => {
            assert.isTrue(false);
          })
          .catch(result => {
              console.log(result);
            assert.isTrue(true);
          })
        });
  });


  it("should not be able to add Player Two move if it is not a player", function () {
    return instance.addToPlayerTwoBalance(playerHash, {from:playerOne, value:web3.toWei('0.1', 'ether')})
    .then (result => {
        return instance.addPlayerTwoMove(playerHash, 0,  { from: owner })
          .then(result => {
            assert.isTrue(false);
          })
          .catch(result => {
              console.log(result);
            assert.isTrue(true);
          })
        });
  });

  it("should not be able to play if a player doesn't activate it.",async function () {

    try {
      await instance.addToPlayerOneBalance(playerHash, {from:playerOne, value:web3.toWei('0.1', 'ether')});
      await instance.addToPlayerTwoBalance(playerHash, {from:playerTwo, value:web3.toWei('0.1', 'ether')});
      await instance.addPlayerOneMove(playerHash,0, {from:playerOne});
      await instance.addPlayerTwoMove(playerHash,0, {from:playerTwo});

    } catch (error) {
      console.log(error);
      assert.isTrue(false);
    }

    return instance.play(playerHash,  { from: owner })
      .then(result => {
        console.log(result);
        assert.isTrue(false);
      })
      .catch(result => {

        assert.isTrue(true);
      })
  });


  it("should not be able to play if a player doesn't have valid hand gestures",async function () {

    try {
      await instance.addToPlayerOneBalance(playerHash, {from:playerOne, value:web3.toWei('0.1', 'ether')});
      await instance.addToPlayerTwoBalance(playerHash, {from:playerTwo, value:web3.toWei('0.1', 'ether')});
      await instance.addPlayerOneMove(playerHash,3, {from:playerOne});
      await instance.addPlayerTwoMove(playerHash,3, {from:playerTwo});

    } catch (error) {
      console.log(error);
      assert.isTrue(true);
    }


    return instance.play(playerHash,  { from: owner })
      .then(result => {
        console.log(result);
        assert.isTrue(false);
      })
      .catch(result => {

        assert.isTrue(true);
      })
  });

  
  it("should  be able to play", async function () {

    try {
      await instance.addToPlayerOneBalance(playerHash, {from:playerOne, value:web3.toWei('0.1', 'ether')});
      await instance.addToPlayerTwoBalance(playerHash, {from:playerTwo, value:web3.toWei('0.1', 'ether')});
      await instance.addPlayerOneMove(playerHash,0, {from:playerOne});
      await instance.addPlayerTwoMove(playerHash,1, {from:playerTwo});

    } catch (error) {
      console.log(error);
      assert.isTrue(false);
    }

    return instance.play(playerHash,  { from: playerOne })
      .then(result => {
        return instance.withdrawWinnings(playerHash,web3.toWei('0.1', 'ether'),  { from: playerTwo })
        .then (result => {
        assert.isTrue(true);
        }
      )
      .catch(result => {
        console.log(result);
        assert.isTrue(false);
      })});
  });

});