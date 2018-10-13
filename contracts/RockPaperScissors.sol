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
  uint private gameNumber = 0;

  mapping (bytes32 => GameStruct) public game;
  mapping (address => uint) public playersBalances;

  event LogAddToPlayerBalanceWithHandGesture(address player, uint balanceAdded,bytes32 gameKey, HandGestureEnum handGestureHash, bool oldWinnings);
  event LogAddToPlayerBalance(address player, uint balanceAdded,bytes32 gameKey, bytes32 handGestureHash, bool oldWinnings);
  event LogWinner(address player, uint winnings);
  event LogWithdrawalAmount(address player, uint amount);
  event LogTransferAmount(address player, uint amount);
  event LogTie(address playerOne, uint playerOneBalance, address playerTwo, uint playerTwoBalance);
  event LogPlayerMoveTotalBalance(address playerOne, uint playerOneBalance);

  constructor() public {

  }

  

  function generateGameKey() public view returns(bytes32) {
	  return keccak256(abi.encodePacked(msg.sender, address(this),gameNumber));
  }

  function generateHandMovement(HandGestureEnum handMovement,bytes32 key) public view returns(bytes32) {
	  return keccak256(abi.encodePacked(address(this),gameNumber,handMovement,key));
  }


  function playerOneStartGameWithFunds(bytes32 gameKey, bytes32 handGestureHash, bool oldWinnings) public payable returns (bytes32)
  {
    emit LogAddToPlayerBalance(msg.sender, msg.value, gameKey, handGestureHash, oldWinnings);
    require (gameKey!=0, "Game key invalid");
    require (game[gameKey].gameStage == GameStage.DoesNotExist,"This game has already started.");
    require (!oldWinnings || (oldWinnings && playersBalances[msg.sender] > 0),"You have no funds to transfer.");
    
    gameNumber += 1;

    game[gameKey].gameStage = GameStage.PlayerOneMoved;

    uint additionalFunds = 0;


    game[gameKey].playerOne = msg.sender;
    game[gameKey].playerOneMoveHash = handGestureHash;
    if (oldWinnings)
    {
      additionalFunds = playersBalances[msg.sender];
      game[gameKey].gameBalances[msg.sender] = 0;
      emit LogWithdrawalAmount(msg.sender,additionalFunds);
    }
    game[gameKey].gameBalances[msg.sender] = msg.value + additionalFunds;
    game[gameKey].playerOneMoveTimestamp = now;

    emit LogPlayerMoveTotalBalance(msg.sender,game[gameKey].gameBalances[msg.sender]);

  }

 
  function playerTwoEnterAndPlayWithFunds(bytes32 gameKey, HandGestureEnum handGesture, bool oldWinnings) public payable
  {
    emit LogAddToPlayerBalanceWithHandGesture(msg.sender, msg.value, gameKey, handGesture, oldWinnings);
    require (gameKey!=0, "Game key invalid");
    require (game[gameKey].gameStage == GameStage.PlayerOneMoved,"This game has already started.");
    require (!oldWinnings || (oldWinnings && playersBalances[msg.sender] > 0),"You have no funds to transfer.");
    
    game[gameKey].gameStage = GameStage.PlayerTwoMoved;

    uint additionalFunds = 0;

    if (oldWinnings)
    {
      additionalFunds = playersBalances[msg.sender];
      game[gameKey].gameBalances[msg.sender] = 0;
      emit LogWithdrawalAmount(msg.sender,additionalFunds);
    }

    game[gameKey].playerTwo = msg.sender;
    game[gameKey].gameBalances[msg.sender] += msg.value + additionalFunds;
    game[gameKey].playerTwoMove = handGesture;

    emit LogPlayerMoveTotalBalance(msg.sender,game[gameKey].gameBalances[msg.sender]);

  }

  function revealResults(bytes32 gameKey,bytes32 playerOnePrivateKey) public
  {
    require (gameKey!=0, "Game key invalid");
    require (game[gameKey].playerOne == msg.sender,"You are not player one in this game.");
    require (game[gameKey].gameStage == GameStage.PlayerTwoMoved,"Not all players have made their moves.");
    game[gameKey].gameStage = GameStage.GameOver;

    HandGestureEnum playerOneHandGesture = HandGestureEnum.None;
    bytes32 playerOneMove = game[gameKey].playerOneMoveHash;
    if (playerOneMove == generateHandMovement(HandGestureEnum.Rock,playerOnePrivateKey))
      playerOneHandGesture = HandGestureEnum.Rock;
    else if (playerOneMove == generateHandMovement(HandGestureEnum.Paper,playerOnePrivateKey))
      playerOneHandGesture = HandGestureEnum.Paper;
    else if (playerOneMove == generateHandMovement(HandGestureEnum.Scissors,playerOnePrivateKey)) 
      playerOneHandGesture = HandGestureEnum.Scissors;

    uint totalWinnings = game[gameKey].gameBalances[game[gameKey].playerOne] + game[gameKey].gameBalances[game[gameKey].playerTwo];

    if (uint(playerOneHandGesture)-uint(game[gameKey].playerTwoMove)+5 % 3 == 0)
    {
      emit LogWinner(game[gameKey].playerOne,totalWinnings);
      playersBalances[game[gameKey].playerOne] += totalWinnings;
      game[gameKey].gameBalances[game[gameKey].playerOne] = 0;
      game[gameKey].gameBalances[game[gameKey].playerTwo] = 0;
    }
    else
    {
      if (uint(playerOneHandGesture)-uint(game[gameKey].playerTwoMove)+5 % 3 == 1)
      {
        emit LogWinner(game[gameKey].playerTwo,totalWinnings);
        playersBalances[game[gameKey].playerTwo] += totalWinnings;
        game[gameKey].gameBalances[game[gameKey].playerOne] = 0;
        game[gameKey].gameBalances[game[gameKey].playerTwo] = 0;
      }
      else
      {
        emit LogTie(game[gameKey].playerOne,game[gameKey].gameBalances[game[gameKey].playerOne], game[gameKey].playerTwo,game[gameKey].gameBalances[game[gameKey].playerTwo]);
        playersBalances[game[gameKey].playerOne] += game[gameKey].gameBalances[game[gameKey].playerOne];
        playersBalances[game[gameKey].playerTwo] += game[gameKey].gameBalances[game[gameKey].playerTwo];
        game[gameKey].gameBalances[game[gameKey].playerOne] = 0;
        game[gameKey].gameBalances[game[gameKey].playerTwo] = 0;
      }
    }
  } 
  
  function withdrawBalance(bytes32 gameKey) public
  {
    require (gameKey!=0, "Game key invalid");
    require (game[gameKey].gameStage == GameStage.GameOver || (game[gameKey].gameStage == GameStage.PlayerTwoMoved && game[gameKey].playerOneMoveTimestamp + timeLimit <= now),"Game has not finished.");
    require (playersBalances[msg.sender] > 0,"You have no funds to transfer.");
    bool timeLimitReached = game[gameKey].gameStage == GameStage.PlayerTwoMoved && game[gameKey].playerOneMoveTimestamp + timeLimit <= now;
    if (timeLimitReached)
    {
      game[gameKey].gameStage = GameStage.GameOver;
      playersBalances[game[gameKey].playerOne] += game [gameKey].gameBalances[game[gameKey].playerOne];
      game[gameKey].gameBalances[game[gameKey].playerOne] = 0;
      playersBalances[game[gameKey].playerTwo] += game [gameKey].gameBalances[game[gameKey].playerTwo];
      game[gameKey].gameBalances[game[gameKey].playerTwo] = 0;
    }
    emit LogWithdrawalAmount(msg.sender,playersBalances[msg.sender]);
    
    uint playerBalance = playersBalances[msg.sender];
    playersBalances[msg.sender] = 0;
    msg.sender.transfer(playerBalance);
  }

}