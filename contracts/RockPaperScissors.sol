pragma solidity 0.4.24;

contract RockPaperScissors {
  enum HandGestureEnum {Rock,Paper,Scissors,None}

  enum GameStage {DoesNotExist, PlayerOneMoved, PlayerTwoMoved, GameOver}

  struct GameStruct {
    address playerOne;
    address playerTwo;
    bytes32 playerOneMoveHash;
    HandGestureEnum playerTwoMove;
    GameStage gameStage;
    uint playerOneMoveTimestamp;
    mapping (address => uint) gameBalances;
  }

  uint timeLimit = 1 days;
  uint private gameNumber;

  mapping (bytes32 => GameStruct) public game;
  mapping (address => uint) public playersAvailableFunds;

  event LogPlayerStartWithHandGesture(address player, bytes32 gameId, HandGestureEnum handGestureHash, uint amountToSpend);
  event LogPlayerStart(address player,bytes32 gameId, bytes32 handGestureHash, uint amountToSpend);
  event LogWinner(address player, uint winnings);
  event LogWithdrawalAmount(address player, uint fundsToWithdraw);
  event LogTie(address playerOne, uint playerOneBalance, address playerTwo, uint playerTwoBalance);
  event LogPlayerMoveTotalBalance(address playerOne, uint playerOneBalance);
  event AbandonGame(address player,bytes32 gameId);
  event LogAddToPlayerFunds(address player,uint funds);

  constructor() public {

  }

  

  function generateGameKey() public view returns(bytes32) {
	  return keccak256(abi.encodePacked(msg.sender, address(this),gameNumber));
  }

  function generateHandMovement(HandGestureEnum handMovement,bytes32 key) public view returns(bytes32) {
	  return keccak256(abi.encodePacked(address(this),gameNumber,handMovement,key));
  }


  function playerOnePlayMove(bytes32 gameId, bytes32 handGestureHash, uint amountToSpend) public  
  {
    emit LogPlayerStart(msg.sender,  gameId, handGestureHash, amountToSpend);
    require (gameId!=0, "Game key invalid");
    GameStruct currentGame = game[gameId];
    require (currentGame.gameStage == GameStage.DoesNotExist,"This game has already started.");
    require ((playersAvailableFunds[msg.sender] >= amountToSpend), "You do not have that much available to spend.");
    
    gameNumber += 1;

    currentGame.gameStage = GameStage.PlayerOneMoved;
    currentGame.playerOne = msg.sender;
    currentGame.playerOneMoveHash = handGestureHash;
    currentGame.gameBalances[msg.sender] +=  amountToSpend;
    playersAvailableFunds[msg.sender] -= amountToSpend;
    currentGame.playerOneMoveTimestamp = now;

    emit LogPlayerMoveTotalBalance(msg.sender,currentGame.gameBalances[msg.sender]);

  }

  function playerTwoEnterPlayMove(bytes32 gameId, HandGestureEnum handGesture, uint amountToSpend) public 
  {
    emit LogPlayerStartWithHandGesture(msg.sender, gameId, handGesture, amountToSpend);
    require (gameId!=0, "Game key invalid");
    GameStruct currentGame = game[gameId];
    require (currentGame.gameStage == GameStage.PlayerOneMoved,"This game has already started.");
    require (playersAvailableFunds[msg.sender] >= amountToSpend,  "You do not have that much available to spend.");
    
    currentGame.gameStage = GameStage.PlayerTwoMoved;
    currentGame.playerTwo = msg.sender;
    currentGame.gameBalances[msg.sender] += amountToSpend;
    playersAvailableFunds[msg.sender] -= amountToSpend;
    currentGame.playerTwoMove = handGesture;

  }

  function convertPlayerOneHandGesture(bytes32 playerOneMoveHash,bytes32 playerOnePrivateKey) private returns (HandGestureEnum handGestureEnum)
  {
      HandGestureEnum playerOneHandGesture = HandGestureEnum.None;

      if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Rock,playerOnePrivateKey))
        playerOneHandGesture = HandGestureEnum.Rock;
      else if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Paper,playerOnePrivateKey))
        playerOneHandGesture = HandGestureEnum.Paper;
      else if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Scissors,playerOnePrivateKey)) 
        playerOneHandGesture = HandGestureEnum.Scissors;

      return (playerOneHandGesture);
  }

  function revealWinnerPlayerOne(bytes32 gameId,bytes32 playerOnePrivateKey) public
  {
    require (gameId!=0, "Game key invalid");
    GameStruct currentGame = game[gameId];
    require (currentGame.playerOne == msg.sender,"You are not player one in this game.");
    require (currentGame.gameStage == GameStage.PlayerTwoMoved,"Not all players have made their moves.");
    currentGame.gameStage = GameStage.GameOver;

    HandGestureEnum playerOneHandGesture = convertPlayerOneHandGesture(currentGame.playerOneMoveHash,playerOnePrivateKey);

    uint availableWinnings = currentGame.gameBalances[currentGame.playerOne] + currentGame.gameBalances[currentGame.playerTwo];
    uint winnerId = uint(playerOneHandGesture)-uint(currentGame.playerTwoMove)+5 % 3;

    if (winnerId == 0)
    {
        emit LogWinner(currentGame.playerOne,availableWinnings);
        playersAvailableFunds[currentGame.playerOne] += availableWinnings;
    }

    if (winnerId == 1) 
    {
        emit LogWinner(currentGame.playerTwo,availableWinnings);
        playersAvailableFunds[currentGame.playerTwo] += availableWinnings;
    }

    if (winnerId > 1)
    {
        emit LogTie(currentGame.playerOne,currentGame.gameBalances[currentGame.playerOne], currentGame.playerTwo,currentGame.gameBalances[currentGame.playerTwo]);
        playersAvailableFunds[currentGame.playerOne] += currentGame.gameBalances[currentGame.playerOne];
        playersAvailableFunds[currentGame.playerTwo] += currentGame.gameBalances[currentGame.playerTwo];
    }
    
    currentGame.gameBalances[currentGame.playerOne] = 0;
    currentGame.gameBalances[currentGame.playerTwo] = 0;
    
  } 

  function addFunds() public payable
  {
    emit LogAddToPlayerFunds(msg.sender, msg.value);
    playersAvailableFunds[msg.sender] += msg.value;
  }
  
  function withdrawFunds(uint fundsToWithdraw) public
  {
    emit LogWithdrawalAmount(msg.sender,fundsToWithdraw);
    require (playersAvailableFunds[msg.sender] > 0,"You have no funds to withdraw.");
    require (playersAvailableFunds[msg.sender] >= fundsToWithdraw,  "You do not have that much available to withdraw.");
    

    
    uint playerBalance = playersAvailableFunds[msg.sender] - fundsToWithdraw;
    playersAvailableFunds[msg.sender] -= fundsToWithdraw;
    msg.sender.transfer(playerBalance);
  }

  function abandonGame(bytes32 gameId) public {
    emit AbandonGame(msg.sender,gameId);
    require (gameId!=0, "Game key invalid");
    GameStruct currentGame = game[gameId];
    require (currentGame.playerOne == msg.sender || currentGame.playerTwo == msg.sender,"Unauthorised");
    require (currentGame.gameStage == GameStage.PlayerTwoMoved,"Cannot withdraw marooned funds unless player two has moved.");
    require (currentGame.playerOneMoveTimestamp + timeLimit <= now, "You cannot withdraw funds until the time limit expires for player one to reveal his hand gesture.");

    currentGame.gameStage = GameStage.GameOver;
    playersAvailableFunds[currentGame.playerOne] += currentGame.gameBalances[currentGame.playerOne];
    currentGame.gameBalances[currentGame.playerOne] = 0;
    playersAvailableFunds[currentGame.playerTwo] += currentGame.gameBalances[currentGame.playerTwo];
    currentGame.gameBalances[currentGame.playerTwo] = 0;
  }

}