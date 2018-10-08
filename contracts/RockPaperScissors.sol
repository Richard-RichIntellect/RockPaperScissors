pragma solidity 0.4.24;

contract RockPaperScissors {
  enum HandGestureEnum {Rock,Paper,Scissors,Nothing}

  struct PlayersStruct
  {
    uint winnings;
    address winnersAddress;
    uint playerOneEntryDateTimeStamp;
    HandGestureEnum playerOneHandGesture;
    bool complete;
  }

  uint timeLimit = 1 days;

  mapping (bytes32 => PlayersStruct) public players;
  mapping (bytes32 => bool) public gameKeyUsed;
  mapping (address => uint) public playersBalances;

  event LogAddToPlayerBalance(address player, uint balanceAdded);
  event LogWinner(address player, uint winnings);
  event LogWithdrawalAmount(address player, uint amount);
  event LogTransferAmount(address player, uint amount);

  constructor() public {

  }

  function generateNewGameKey() public view returns(bytes32) {
	  return keccak256(abi.encodePacked(msg.sender,now, address(this)));
  }



  function playerOneStartGameWithFunds(bytes32 playersUniqueKey,HandGestureEnum handGesture, bytes32 oldWinnings) public payable 
  {
	  emit LogAddToPlayerBalance(msg.sender, msg.value);
    uint additionalFunds = 0;
    if (oldWinnings!=0)
    {
      require (players[playersUniqueKey].winnersAddress == msg.sender,"Unathorized request.");
      require (players[playersUniqueKey].winnings != 0,"No funds to transfer");
      require (!gameKeyUsed[playersUniqueKey],"Game key has been used.");
      gameKeyUsed[playersUniqueKey] = true;
      additionalFunds = players[playersUniqueKey].winnings;
      players[playersUniqueKey].winnings = 0;
      emit LogWithdrawalAmount(msg.sender,additionalFunds);
    }
    players[playersUniqueKey].winnings = msg.value + additionalFunds;
    players[playersUniqueKey].winnersAddress = msg.sender;
    players[playersUniqueKey].playerOneHandGesture = handGesture;
    players[playersUniqueKey].playerOneEntryDateTimeStamp = now;
  }

 
  function playerTwoEnterAndPlayWithFunds(bytes32 playersUniqueKey, HandGestureEnum handGesture, bytes32 oldWinnings) public payable
  {
    emit LogAddToPlayerBalance(msg.sender, msg.value);
    require (players[playersUniqueKey].playerOneEntryDateTimeStamp!=0,"Cannot find matching game key");
    require (playersUniqueKey!=0,"playersUniqueKey required");
    require (!players[playersUniqueKey].complete,"Game completed.");
    players[playersUniqueKey].complete = true;
    uint additionalFunds = 0;

    if (oldWinnings!=0)
    {

      require (players[playersUniqueKey].winnersAddress == msg.sender,"Unathorized request.");
      require (players[playersUniqueKey].winnings != 0,"No funds to transfer");
      additionalFunds = players[oldWinnings].winnings;
      players[oldWinnings].winnings = 0;
      emit LogTransferAmount(msg.sender,additionalFunds);

    }

    uint totalWinningsAmount = players[playersUniqueKey].winnings + msg.value + additionalFunds;
   
    if (uint(players[playersUniqueKey].playerOneHandGesture)-uint(handGesture)+5 % 3 == 0)
    {
      emit LogWinner(players[playersUniqueKey].winnersAddress,totalWinningsAmount);
      playersBalances[players[playersUniqueKey].winnersAddress] += totalWinningsAmount;
    }
    else
    {
      if (uint(players[playersUniqueKey].playerOneHandGesture)-uint(handGesture)+5 % 3 == 1)
      {
        emit LogWinner(msg.sender,players[playersUniqueKey].winnings);
        playersBalances[msg.sender] += totalWinningsAmount;
        players[playersUniqueKey].winnersAddress = msg.sender;
      }
      else
      {
        revert("It's a tie!");
      }
    }
  }
  
  
  function withdrawBalance(bytes32 playersUniqueKey) public
  {
    require (playersUniqueKey!=0,"playersUniqueKey required");
    require (players[playersUniqueKey].winnersAddress == msg.sender,"Invalid address");
    require (playersBalances[msg.sender] > 0,"No funds available");
    require (players[playersUniqueKey].complete || (!players[playersUniqueKey].complete && players[playersUniqueKey].playerOneEntryDateTimeStamp + timeLimit <= now),"Cannot withdraw funds.");
    emit LogWithdrawalAmount(msg.sender,players[playersUniqueKey].winnings);
    uint playerBalance = playersBalances[msg.sender];
    playersBalances[msg.sender] = 0;
    players[playersUniqueKey].winnersAddress.transfer(playerBalance);
  }

}