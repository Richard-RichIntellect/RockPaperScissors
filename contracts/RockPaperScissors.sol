pragma solidity 0.4.24;

contract RockPaperScissors {
  enum HandGestureEnum {Rock,Paper,Scissors,None}
  enum GameEnum {Tie, PlayerOneWin,PlayerTwoWin }
  enum GameStage {DoesNotExist, PlayerOneMoved, PlayerTwoMoved, GameOver}

  struct GameStruct {
    address playerOne;
    address playerTwo;
    bytes32 playerOneMoveHash;
    HandGestureEnum playerTwoMove;
    GameStage gameStage;
    uint deadline;
    mapping (address => uint) gameBalances;
  }

  uint timeLimit = 1 hours;
  uint private gameNumber;

  mapping (bytes32 => GameStruct) public game;
  mapping (address => uint) public playersAvailableFunds;

  event LogplayerTwoEnterPlayMove(address player, bytes32 gameId, HandGestureEnum handGestureHash, uint amountToSpend);
  event LogplayerOnePlayMove(address player,bytes32 gameId, bytes32 handGestureHash, uint amountToSpend);
  event LogWinnerPlayerOne(address player, uint winnings);
  event LogWinnerPlayerTwo(address player, uint winnings);
  event LogWithdrawalAmount(address player, uint fundsToWithdraw);
  event LogTie(address playerOne, uint playerOneBalance, address playerTwo, uint playerTwoBalance);
  event LogPlayerMoveTotalBalance(address playerOne, uint playerOneBalance);
  event LogplayerOneClaimsPlayerTwoNoShow(address player,bytes32 gameId);
  event LogplayerTwoClaimsPlayerOnesWinning(address player,bytes32 gameId);
  event LogAddToPlayerFunds(address player,uint funds);

  event LogDebug(uint win, uint lose, uint tie, uint winnerId);

  constructor() public {

  }

  function generateGameKey() public view returns(bytes32) {
    return keccak256(abi.encodePacked(msg.sender, address(this),gameNumber));
  }

  function generateHandMovement(HandGestureEnum handMovement,bytes32 key) public view returns(bytes32) {
    return keccak256(abi.encodePacked(address(this),handMovement,key));
  }


  function playerOnePlayMove(bytes32 gameId, bytes32 handGestureHash, uint amountToSpend) public  
  {

    require (gameId!=0, "Game key invalid");
    require (handGestureHash!=0, "handGestureHash is invalid");
    GameStruct storage currentGame = game[gameId];
    require (currentGame.gameStage == GameStage.DoesNotExist,"This game has already started.");
    require ((playersAvailableFunds[msg.sender] >= amountToSpend), "You do not have that much available to spend.");
    emit LogplayerOnePlayMove(msg.sender,  gameId, handGestureHash, amountToSpend);

    gameNumber += 1;

    currentGame.gameStage = GameStage.PlayerOneMoved;
    currentGame.playerOne = msg.sender;
    currentGame.playerOneMoveHash = handGestureHash;
    currentGame.gameBalances[msg.sender] += amountToSpend;
    playersAvailableFunds[msg.sender] -= amountToSpend;
    currentGame.deadline = now + timeLimit;

    emit LogPlayerMoveTotalBalance(msg.sender,currentGame.gameBalances[msg.sender]);

  }

  function playerTwoEnterPlayMove(bytes32 gameId, HandGestureEnum handGesture, uint amountToSpend) public 
  {
    require (gameId!=0, "Game key invalid");
    GameStruct storage currentGame = game[gameId];
    require (currentGame.gameStage == GameStage.PlayerOneMoved,"You cannot play your move until player one has completed his.");
    require (playersAvailableFunds[msg.sender] >= amountToSpend,  "You do not have that much available to spend.");
    require (currentGame.gameBalances[currentGame.playerOne] == amountToSpend,"You must bet the same amount as player one.");
    emit LogplayerTwoEnterPlayMove(msg.sender, gameId, handGesture, amountToSpend);

    currentGame.gameStage = GameStage.PlayerTwoMoved;
    currentGame.playerTwo = msg.sender;
    currentGame.gameBalances[msg.sender] += amountToSpend;
    playersAvailableFunds[msg.sender] -= amountToSpend;
    currentGame.playerTwoMove = handGesture;

  }

  function convertPlayerOneHandGesture(bytes32 playerOneMoveHash,bytes32 playerOnePrivateKey) public view returns (HandGestureEnum)
  {
    HandGestureEnum playerOneHandGesture = HandGestureEnum.None;

    if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Rock,playerOnePrivateKey))
        playerOneHandGesture = HandGestureEnum.Rock;
    else if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Paper,playerOnePrivateKey))
        playerOneHandGesture = HandGestureEnum.Paper;
    else if (playerOneMoveHash == generateHandMovement(HandGestureEnum.Scissors,playerOnePrivateKey)) 
        playerOneHandGesture = HandGestureEnum.Scissors;
    else
        playerOneHandGesture = HandGestureEnum.None;

    return (playerOneHandGesture);
  }

  function revealWinnerPlayerOne(bytes32 gameId,bytes32 playerOnePrivateKey) public
  {
    require (gameId!=0, "Game key invalid");
    GameStruct storage cg = game[gameId];
    require (cg.playerOne == msg.sender,"You are not player one in this game.");
    require (cg.gameStage == GameStage.PlayerTwoMoved,"Not all players have made their moves.");
    cg.gameStage = GameStage.GameOver;

    HandGestureEnum playerOneHandGesture = convertPlayerOneHandGesture(cg.playerOneMoveHash,playerOnePrivateKey);

    uint availableWinnings = cg.gameBalances[cg.playerOne] + cg.gameBalances[cg.playerTwo];
    uint winnerId = (uint(playerOneHandGesture)-uint(cg.playerTwoMove)) % 3;

    if (winnerId == uint(GameEnum.PlayerOneWin))
    {
      emit LogWinnerPlayerOne(cg.playerOne,availableWinnings);
      playersAvailableFunds[cg.playerOne] += availableWinnings;
    }

    if (winnerId == uint(GameEnum.PlayerTwoWin)) 
    {
      emit LogWinnerPlayerTwo(cg.playerTwo,availableWinnings);
      playersAvailableFunds[cg.playerTwo] += availableWinnings;
    }

    if (winnerId == uint(GameEnum.Tie))
    {
      emit LogTie(cg.playerOne,cg.gameBalances[cg.playerOne], cg.playerTwo,cg.gameBalances[cg.playerTwo]);
      playersAvailableFunds[cg.playerOne] += cg.gameBalances[cg.playerOne];
      playersAvailableFunds[cg.playerTwo] += cg.gameBalances[cg.playerTwo];
    }

    cg.gameBalances[cg.playerOne] = 0;
    cg.gameBalances[cg.playerTwo] = 0;
    
  } 

  function addFunds() public payable
  {
    emit LogAddToPlayerFunds(msg.sender, msg.value);
    playersAvailableFunds[msg.sender] += msg.value;
  }
  
  function withdrawFunds(uint fundsToWithdraw) public
  {

    require (playersAvailableFunds[msg.sender] > 0,"You have no funds to withdraw.");
    require (playersAvailableFunds[msg.sender] >= fundsToWithdraw,  "You do not have that much available to withdraw.");
    emit LogWithdrawalAmount(msg.sender,fundsToWithdraw);

    uint playerBalance = playersAvailableFunds[msg.sender] - fundsToWithdraw;
    playersAvailableFunds[msg.sender] -= fundsToWithdraw;
    msg.sender.transfer(playerBalance);
  }

  function playerOneClaimsPlayerTwoNoShow(bytes32 gameId) public {
    require (gameId!=0, "Game key invalid");
    GameStruct storage cg = game[gameId];
    require (cg.gameStage == GameStage.PlayerOneMoved,"Invalid");
    require (cg.deadline  <= now, "You cannot abandon game until the time limit expires.");
    emit LogplayerOneClaimsPlayerTwoNoShow(msg.sender,gameId);

    playersAvailableFunds[game[gameId].playerOne] += cg.gameBalances[cg.playerOne]; 
    cg.gameBalances[cg.playerOne] = 0;
    cg.gameBalances[cg.playerTwo] = 0;
  }

  function playerTwoClaimsPlayerOnesWinning(bytes32 gameId) public {
    require (gameId!=0, "Game key invalid");
    GameStruct storage cg = game[gameId];
    require (cg.gameStage == GameStage.PlayerTwoMoved,"Invalid");
    require (cg.deadline  <= now, "You cannot abandon game until the time limit expires.");
    emit LogplayerTwoClaimsPlayerOnesWinning(msg.sender,gameId);

    playersAvailableFunds[cg.playerTwo] += (cg.gameBalances[cg.playerOne] + cg.gameBalances[cg.playerTwo]);
    cg.gameBalances[cg.playerOne] = 0;
    cg.gameBalances[cg.playerTwo] = 0;
  }

}