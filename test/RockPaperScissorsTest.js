const RockPaperScissors = artifacts.require("../contracts/RockPaperScissors.sol");
const expectedExceptionPromise = require("./expected_exception_testRPC_and_geth.js");

contract('RockPaperScissors', function (accounts) {
  let instance;
  let gameKey;
  let playerOneBalance;
  let playerTwoBalance;


  const playerOne = accounts[0];
  const playerTwo = accounts[1];
  const owner = accounts[2];

  const emptyAddress = /^0x0+$/

  beforeEach(function () {
    return RockPaperScissors.new({ from: owner })
      .then(async function (_instance) {
        instance = _instance;

        playerOneBalance = await web3.eth.getBalance(playerOne);
        playerTwoBalance = await web3.eth.getBalance(playerTwo);
        return instance.generateGameKey()
      .then(result => {
        console.log(result)
        gameKey = result;
      })
     
  })
 }) ;




console.log(!instance);

// describe("A suite of functions to test RockPaperScissors", function () { 

//   beforeEach(function () {
//     return instance.playerOneStartGameWithFunds(playersHash, 0, 0, { from: playerOne, value: web3.toWei('0.1', 'ether') })
//     .catch(results => console.log(results)); 
//   });

//   it("should not be able to to let player two play if password hash is empty", function () {
//     console.log(!instance);
//     return instance.playerOneStartGameWithFunds(playersHash, 0, 0, { from: owner })
//       .then(result => {
//         assert.isTrue(false);
//       })
//       .catch(result => {
//         console.log(result);
//         assert.isTrue(true);
//       })
//   });
  
//   it("should not be able to allow player two to play if game already completed.", async function () {
  
//     await instance.playerOneStartGameWithFunds(playersHash, 1,0, { from: playerTwo, value: web3.toWei('0.1', 'ether') })
  
//     return instance.playerOneStartGameWithFunds(playersHash, 1,0, { from: playerTwo, value: web3.toWei('0.1', 'ether') })
//       .then(result => {
//         console.log(result);
//         assert.isTrue(false);
//       })
//       .catch(result => {
//         console.log(result);
//         assert.isTrue(true);
//       })
//   });
  
//   it("should not be able to allow player two to play betting amount is not equal.", function () {
  
//     return instance.playerOneStartGameWithFunds(playersHash, 0,0, { from: playerTwo, value: web3.toWei('0.01', 'ether') })
//       .then(result => {
//         assert.isTrue(false);
//       })
//       .catch(result => {
//         console.log(result);
//         assert.isTrue(true);
//       })
//   });
  
//   it("should not be able to withdraw balance if hash is empty.", async function () {
  
//     await instance.playerOneStartGameWithFunds(playersHash, 1,0, { from: playerTwo, value: web3.toWei('0.01', 'ether') })
  
//     return instance.withdrawBalance(0, { from: playerTwo })
//       .then(result => {
//         assert.isTrue(false);
//       })
//       .catch(result => {
//         console.log(result);
//         assert.isTrue(true);
//       })
//   });
// });

let handMovement;

describe ("A suite of functions to test RockPaperScissors with new instance", () =>{ 

    beforeEach(function () {
      return instance.generateHandMovement(0,playerOne)
      .then(result => handMovement = result)
      .catch(results => console.log(results)); 
    });

    beforeEach(function () {
      return instance.playerOneStartGameWithFunds(gameKey, handMovement, false, { from: playerOne, value: web3.toWei('0.1', 'ether') });
      
    });



  //   it("should not be able to withdraw balance unless you are the winner.", async function () {

  //     await instance.playerTwoEnterAndPlayWithFunds(newHash, 1, 0, { from: playerTwo, value: web3.toWei('0.1', 'ether') })

  //     return expectedExceptionPromise(function () {return instance.withdrawBalance(newHash, { from: owner });
 
  //   });
  // });


  //   it("should not be able to transfer balance unless you are the winner in the prior game.", async function () {

  //     await instance.playerTwoEnterAndPlayWithFunds(newHash, 1, 0, { from: playerTwo, value: web3.toWei('0.1', 'ether') })

  //     let anotherNewHash = await instance.generateNewGameKey();

  //     await instance.playerOneStartGameWithFunds(anotherNewHash, 0,0, { from: owner, value: web3.toWei('0.1', 'ether') });

  //     return instance.playerTwoEnterAndPlayWithFunds(anotherNewHash, 1, newHash, { from: playerTwo })
  //       .then(result => {
  //         assert.isTrue(false);
  //       })
  //       .catch(result => {
  //         console.log(result);
  //         assert.isTrue(true);
  //       })
  //   });



  //   it("should not be able to transfer balance unless you have funds.", async function () {

  //     await instance.playerTwoEnterAndPlayWithFunds(newHash, 1, 0, { from: playerTwo, value: web3.toWei('0.1', 'ether') });

  //     await instance.withdrawBalance(newHash, { from: playerTwo });


  //     let anotherNewHash = await instance.generateNewGameKey();

  //     await instance.playerOneStartGameWithFunds(anotherNewHash, 0, 0, { from: playerOne, value: web3.toWei('0.1', 'ether') });

  //     return instance.playerTwoEnterAndPlayWithFunds(anotherNewHash, 1,0, newHash, { from: playerTwo, value: web3.toWei('0.0', 'ether') })
  //       .then(result => {
  //         assert.isTrue(false);
  //       })
  //       .catch(result => {
  //         console.log(result);
  //         assert.isTrue(true);
  //       })
  //   });



    it("should allow Player one to win.", async function () {

      await instance.playerTwoEnterAndPlayWithFunds(gameKey, 2, false,  { from: playerTwo, value: web3.toWei('0.01', 'ether') });
      await instance.revealResults(gameKey, gameKey,  { from: playerOne })

      return instance.withdrawBalance(gameKey, { from: playerOne })
        .then(result => {
          assert.isTrue(true);
        })      
    });



    it("should allow Player two to win.", async function () {

      await instance.playerTwoEnterAndPlayWithFunds(gameKey, 1, false,  { from: playerTwo, value: web3.toWei('0.01', 'ether') })

      await instance.revealResults(gameKey, gameKey,  { from: playerOne})

      return instance.withdrawBalance(gameKey, { from: playerTwo })
        .then(result => {
          assert.isTrue(true);
        })
        

    });

    it("should allow a draw.", async function () {

      await instance.playerTwoEnterAndPlayWithFunds(gameKey, 0, false,  { from: playerTwo, value: web3.toWei('0.01', 'ether') })

      await instance.revealResults(gameKey, gameKey,  { from: playerOne })

      return instance.withdrawBalance(gameKey, { from: playerOne })
        .then(result => {
          return instance.withdrawBalance(gameKey, { from: playerTwo })
        })
        .then(result => {
          assert.isTrue(true);
        })
       

        
    });
  });
});