pragma solidity 0.4.24;

contract RockPaperScissors {
  enum HandGestureEnum {Rock,Paper,Scissors,Nothing}

  struct PlayersStruct
  {
    uint playerOneBalance;
    uint playerTwoBalance;
    address playerOneAddress;
    address playerTwoAddress;
    HandGestureEnum playerOneHandGesture;
    HandGestureEnum playerTwoHandGesture;
  }

  mapping (bytes32 => PlayersStruct) public players;

  event LogReturnPlayersKeyAddresses(address playerOneAddr, address playerTwoAddr);
  event LogAddToPlayerBalance(address player, uint balanceAdded);
  event LogPlayersMove(address player, HandGestureEnum handGesture);
  event LogWinner(address player, uint winnings);
  event LogWithdrawalAmount(address player, uint amount);

  constructor() public {

  }

  function returnPlayersKey(address playerOneAddr, address playerTwoAddr) public view returns(bytes32) {
    require (playerOneAddr != address(0),"Player one address required");
    require (playerTwoAddr != address(0),"Player two address required");
    return keccak256(abi.encodePacked(playerOneAddr,playerTwoAddr, address(this)));
  }

  function addToPlayerOneBalance(bytes32 playersUniqueKey) public payable
  {
    emit LogAddToPlayerBalance(msg.sender, msg.value);
    require (playersUniqueKey!=0,"playersUniqueKey required");
    players[playersUniqueKey].playerOneBalance += msg.value;
    players[playersUniqueKey].playerOneAddress = msg.sender;
  }

  function addToPlayerTwoBalance(bytes32 playersUniqueKey) public payable
  {
    emit LogAddToPlayerBalance(msg.sender, msg.value);
    require (playersUniqueKey!=0,"playersUniqueKey required");
    players[playersUniqueKey].playerTwoBalance += msg.value;
    players[playersUniqueKey].playerTwoAddress = msg.sender;
  }

  function addPlayerOneMove(bytes32 playersUniqueKey, HandGestureEnum handGesture) public
  {
    emit LogPlayersMove(msg.sender, handGesture);
    require (playersUniqueKey!=0,"playersUniqueKey required");
    bytes32 localKey = returnPlayersKey(msg.sender, players[playersUniqueKey].playerTwoAddress);
    require (localKey == playersUniqueKey,"Invalid playersUniqueKey");
    players[playersUniqueKey].playerOneHandGesture = handGesture;
  }

  function addPlayerTwoMove(bytes32 playersUniqueKey, HandGestureEnum handGesture) public
  {
    emit LogPlayersMove(msg.sender, handGesture);
    require (playersUniqueKey!=0,"playersUniqueKey required");
    bytes32 localKey = returnPlayersKey(players[playersUniqueKey].playerOneAddress, msg.sender);
    require (localKey == playersUniqueKey,"Invalid playersUniqueKey");
    players[playersUniqueKey].playerTwoHandGesture = handGesture;
  }

  function play(bytes32 playersUniqueKey) public
  {
    require (players[playersUniqueKey].playerOneAddress == msg.sender || players[playersUniqueKey].playerOneAddress == msg.sender,"Unathorized command");
    require (playersUniqueKey!=0,"playersUniqueKey required");
    require (players[playersUniqueKey].playerOneHandGesture != HandGestureEnum.Nothing,"Player One has not decided gesture");
    require (players[playersUniqueKey].playerTwoHandGesture != HandGestureEnum.Nothing,"Player Two has not decided gesture");
    

    uint winnings = players[playersUniqueKey].playerOneBalance + players[playersUniqueKey].playerTwoBalance;
    players[playersUniqueKey].playerOneHandGesture = HandGestureEnum.Nothing;
    players[playersUniqueKey].playerTwoHandGesture = HandGestureEnum.Nothing;      
    
    if (uint(players[playersUniqueKey].playerOneHandGesture)-uint(players[playersUniqueKey].playerTwoHandGesture)+5 % 3 == 0)
    {
      emit LogWinner(players[playersUniqueKey].playerOneAddress,winnings);
      players[playersUniqueKey].playerOneBalance = winnings;
      players[playersUniqueKey].playerTwoBalance = 0;
    }
    else
    {
      emit LogWinner(players[playersUniqueKey].playerTwoAddress,winnings);
      players[playersUniqueKey].playerOneBalance = 0;
      players[playersUniqueKey].playerTwoBalance = winnings;
    }
  }

  function withdrawWinnings(bytes32 playersUniqueKey, uint withdrawalAmount) public
  {

    require (playersUniqueKey!=0,"playersUniqueKey required");
    require (withdrawalAmount > 0,"withdrawalAmount must be greater than zero");
    require (players[playersUniqueKey].playerOneAddress == msg.sender || players[playersUniqueKey].playerTwoAddress == msg.sender,"Unathorized withdrawal");
    
    if (players[playersUniqueKey].playerOneAddress == msg.sender) {
      emit LogWithdrawalAmount(players[playersUniqueKey].playerOneAddress, withdrawalAmount);
      require(players[playersUniqueKey].playerOneBalance >= withdrawalAmount, "Insufficient funds.");
      players[playersUniqueKey].playerOneBalance -= withdrawalAmount;
      players[playersUniqueKey].playerOneAddress.transfer(withdrawalAmount);
    }

    if (players[playersUniqueKey].playerTwoAddress == msg.sender) {
      emit LogWinner(players[playersUniqueKey].playerTwoAddress,withdrawalAmount);
      require(players[playersUniqueKey].playerTwoBalance >= withdrawalAmount, "Insufficient funds.");
      players[playersUniqueKey].playerTwoBalance -= withdrawalAmount;
      players[playersUniqueKey].playerTwoAddress.transfer(withdrawalAmount);
    }

  }

}