/** This file was auto-generated by jpp.  You probably want to be editing ./PostBox.uc.jpp instead. **/



// PostBox
// Lets players on your server leave messages for each other.
// vim: tabstop=2 shiftwidth=2 noexpandtab filetype=uc

// Changes:
// Added ENABLE_PRIVATE_MESSAGES.

// TODO: feature requests on UnrealAdmin:
//       longer time before welcome message DISappears - check how BDBMapVote does this   (and maybe make check-time configurable)
// DONE: allow spectators to read their messages

// TODO: let individual players turn PostBox on/off entirely.

// CONSIDER TODO: let players leave messages at specific points on a map, so
// they are displayed (to all players, or to specific friends?) when that part
// of the map is visited.  (Could be nice for MH/BT maps.)

// CONSIDER TODO: let players leave map-wide or server-wide messages for all
// players - like a forum - maybe rotate after 5/10 messages.

// DONE: if someone has a similar nick to you, and a passworded account, and a
// message waiting before your message, then you will be unable to clear their
// message, and unable to read the message intended for you!
//
// This could even be exploited by a malicious user.  If they create a
// passworded account for every letter of the alphabet, and post to each of
// them, nobody else will be able to receive posts!
//
// Possible solutions: skip to the next message if you don't have the
// password for the first one (DONE); force account/recipient names to be at
// least 5 chars.

// CONSIDER: probably overkill, but could make it more like a real mail account, with !list, and !clear (don't delete messages immediately).

// CONSIDER TODO: add a !search command, to list passworded accounts, so you can find your friend's account

// DONE: As well as informing each user of new mail when they join the
// server, we could also remind them at the end of the game (during warm-down
// or mapvote).  Make both optional.




class PostBox expands Mutator config(PostBox);

var config bool bCheckMailOnPlayerJoin;
var config bool bCheckMailAtEndOfGame;
var config bool bAnnounceOnJoin;
var config bool bSuggestReply;
var config bool bSendConfirmationMessage;

var config bool bRecommendPasswording;


var config bool bAcceptSpokenCommands;
var config bool bAcceptMutateCommands;
// var config bool bSwallowSpokenCommands; // Now it is swallowing specific commands automatically.


var config String mailFrom[4096];
var config String mailTo[4096];
var config String mailDate[4096];
var config String mailMessage[4096];



var config String accountName[2048];
var config String accountPass[2048];


var int lastPlayerChecked;

defaultproperties {
  bCheckMailOnPlayerJoin=True
  bCheckMailAtEndOfGame=True
  bAnnounceOnJoin=False
  bSuggestReply=False // Can be a bit too spammy
  bSendConfirmationMessage=False // Can be a bit too spammy

  bRecommendPasswording=False // Can be a bit too spammy

  bAcceptSpokenCommands=True
  bAcceptMutateCommands=True
  // bSwallowSpokenCommands=True
  lastPlayerChecked=0
}

// TODO: loop through all mails, when reading (show first), and when checking for new (count)


// CONSIDER: immediate notification when new message is created for a player currently on server?  aka private message

function PostBeginPlay() {
 // If we were not added as a mutator, but run in some other way (e.g. as a ServerActor), then we need to register as a mutator:
   // Level.Game.BaseMutator.AddMutator(Self);

 // Register to receive spoken messages in MutatorTeamMessage() below:
 if (bAcceptSpokenCommands) {
  Level.Game.RegisterMessageMutator(Self);
 }

 SetTimer(29,True); // 15 was too fast; appeared right after gamestart, along with the zp info

 Super.PostBeginPlay();
}

// Catch messages from spectators:
function bool MutatorBroadcastMessage(Actor Sender, Pawn Receiver, out coerce string Msg, optional bool bBeep, out optional name Type) {
 local bool hideMessage;
 hideMessage = SuperCheckMessage(Sender,Receiver,Mid(Msg,InStr(Msg,":")+1));
 return Super.MutatorBroadcastMessage(Sender,Receiver,Msg,bBeep,Type) && (!hideMessage); // || !bSwallowSpokenCommands);
}

// Catch messages from players:
function bool MutatorTeamMessage(Actor Sender, Pawn Receiver, PlayerReplicationInfo PRI, coerce string Msg, name Type, optional bool bBeep) {
 local bool hideMessage;
 hideMessage = SuperCheckMessage(Sender,Receiver,Msg);
 return Super.MutatorTeamMessage(Sender,Receiver,PRI,Msg,Type,bBeep) && (!hideMessage); // || !bSwallowSpokenCommands);
}

// Returns True if this message should be swallowed / hidden from other players.
function bool SuperCheckMessage(Actor Sender, Pawn Receiver, String Msg) {
 if (StrStartsWith(Msg,"!") || StrStartsWith(Caps(Msg),"/MSG")) {
  if (Sender == Receiver && Sender.IsA('PlayerPawn')) { // Only process each message once.
   CheckMessage(Mid(Msg,1), PlayerPawn(Sender));
  }
  if (StrStartsWith(Locs(Msg),"!mail") || StrStartsWith(Locs(Msg),"!post") || StrStartsWith(Locs(Msg),"!read") || StrStartsWith(Locs(Msg),"!setpass") || StrStartsWith(Locs(Msg),"!changepass") || StrStartsWith(Locs(Msg),"!msg") || StrStartsWith(Locs(Msg),"/msg")) {
   // We hide/swallow the first two and the last two for privacy, and we hide !read to save space in the player's chat area
   // Note this is separate from the Sender == Receiver check, since we want to swallow/hide this message from ALL players!
   return True;
  }
 }
 return False;
}

function Mutate(String str, PlayerPawn Sender) {
 if (bAcceptMutateCommands) {
  CheckMessage(str, Sender);
 }
 Super.Mutate(str, Sender);
}

// Returns True if the command was recognised.
function bool CheckMessage(String line, PlayerPawn Sender) {
 local int argCount;
 local String args[256];
 local Actor A;
 local String command;
 local int i;

 // Log("PostBox.uc.CheckMessage() ("$Sender$"): "$line$"");
 argcount = SplitString(line," ",args);
 command = args[0];

 if (command ~= "HELP") {
  Sender.ClientMessage("PostBox commands: !help !read");
  Sender.ClientMessage("  !mail/!post <part_of_player's_nick> <message>");

  Sender.ClientMessage("  !msg <nick> <message>");


  Sender.ClientMessage("  !setpass <account> <password>");
  Sender.ClientMessage("  !changepass <account> <old_pass> <new_pass>");

  return True;
 }

 if (command ~= "READ") {
  ReadMail(Sender,args[1]);
  return True;
 }

 if (command ~= "MAIL" || command ~= "POST") {
  if (args[1] == "" || args[2] == "") {
   Sender.ClientMessage("Usage: !mail <part_of_player's_nick> <message>");
  } else {
   // Save message args[2..] for args[1] (from Sender)
   PostMail(Sender,args[1],StrAfter(StrAfter(line," ")," "));
  }
  return True;
 }


  if (command ~= "MSG") {
   SendPrivateMessage(Sender,args[1],args[2]);
  }



 if (command ~= "SETPASS") {
  if (args[1] == "" || args[2] == "") {
   Sender.ClientMessage("Usage: !setpass <account_name> <password>");
  } else {
   SetPass(Sender,args[1],args[2]);

  }
  return True;
 }

 if (command ~= "CHANGEPASS") {
  if (args[1] == "" || args[2] == "" || args[3] == "") {
   Sender.ClientMessage("Usage: !changepass <account_name> <old_pass> <new_pass>");
  } else {
   for (i=0;i<2048;i++) {
    if (accountName[i] ~= args[1]) {
     if (accountPass[i] ~= args[2]) {
      accountPass[i] = args[3];
      Sender.ClientMessage("Your password for account "$accountName[i]$" has been changed.");
     } else {
      Sender.ClientMessage("Wrong password.");
     }
     break;
    }
   }
   // BUG: no handling if account was not found
  }
  return True;
 }


 return False;

}

function PostMail(PlayerPawn Sender, String to, String message) {
 local int i;
 to = squishString(to);
 if (Len(to) < 5) {
  Sender.ClientMessage("I'm sorry, the target nick must contain at least 5 letters.");
 }
 for (i=0; i<4096; i++) {
  if (mailFrom[i] == "" && mailTo[i] == "" && mailDate[i] == "" && mailMessage[i] == "") {
   mailFrom[i] = Sender.GetHumanName();
   mailTo[i] = to;
   mailDate[i] = GetDate();
   mailMessage[i] = message;

   if (isPassworded(to)) {
    Sender.ClientMessage("Message for " $ to $ " (passworded account) has been saved.");
   } else {
    Sender.ClientMessage("Message for " $ to $ " has been saved.");
   }



   SaveConfig();
   break;
  }
 }
 if (i == 4096) {
  Sender.ClientMessage("I'm sorry, the mailbox is full!  Please contact the server admin.");
 }
}

// Removes all non-alphanumeric characters from a string
function String squishString(String str) {
 local String newStr;
 local int i,c;
 // str = Caps(str);
 str = Locs(str);
 newStr = "";
 for (i=0; i<Len(str); i++) {
  c = Asc(Mid(str,i,1));
  // if ( (c>=Asc("A") && c<=Asc("Z")) || (c>=Asc("0") && c<=Asc("9")) ) {
  if ( (c>=Asc("a") && c<=Asc("z")) || (c>=Asc("0") && c<=Asc("9")) ) {
   newStr = newStr $ Chr(c);
  }
 }
 return newStr;
}

event Timer() {
 local Pawn p;

 if (bCheckMailAtEndOfGame && Level.Game.bGameEnded) {
  // I want to check mail for all players, but i don't want to announce this time
  for (p=Level.PawnList; p!=None; p=p.NextPawn) {
   if (p.IsA('PlayerPawn')) {
    CheckMailFor(PlayerPawn(p));
   }
  }
  SetTimer(0,False); // CONSIDER: Alternatively, we could set bEndGameCheckDone, and continue checking for new players who join after the end of the game.
  // Problem: now new players joining during this end-game period won't be checked :|
  // But we'll need another bloody variable, to set whether we have done the all-players end-game mailcheck.  :P
  return;
 }

 if (bCheckMailOnPlayerJoin) {
  CheckForNewPlayers();
 }
}

function CheckForNewPlayers() {
 local Pawn p;
 while (Level.Game.CurrentID > lastPlayerChecked) {
  for (p=Level.PawnList; p!=None; p=p.NextPawn) {
   if (p.IsA('PlayerPawn') && p.PlayerReplicationInfo.PlayerID == lastPlayerChecked) {
    ProcessNewPlayer(PlayerPawn(p));
    break;
   }
  }
  lastPlayerChecked++;
 }
}

function ProcessNewPlayer(PlayerPawn p) {
 // Check for new mail for this player:
 if ( ! CheckMailFor(p) ) {
  // Only announce the mutator if they didn't have new mail:
  if (bAnnounceOnJoin) {
   p.ClientMessage("This server is running the PostBox mutator.");
   p.ClientMessage("You can leave messages for other players with the !mail command.");
  }
 }
}

/*

function int FindMailFor(PlayerPawn p) {

	local String squishedName;

	local int i;

	// Check for mail for Sender

	squishedName = squishString(p.GetHumanName());

	for (i=0; i<MAX_MAILS; i++) {

		if (mailTo[i] != "" && StrContains(squishedName,squishString(mailTo[i]))) {

			return i;

		}

	}

	return -1;

}

*/
function bool CheckMailFor(PlayerPawn p) {
 local String squishedName;
 local int i;
 // local int count;
 // count = 0;
 squishedName = squishString(p.GetHumanName());
 for (i=0;i<4096;i++) {
  if (mailTo[i]!="" && StrContains(squishedName,squishString(mailTo[i]))) {
   if (isPassworded(mailTo[i])) {
    p.ClientMessage(mailFrom[i]$" has left you a message.  Type !read <password> to read it.");
   } else {
    p.ClientMessage(mailFrom[i]$" has left you a message.  Type !read to read it.");
   }
   // count++;
   return True;
  }
 }
 return False;
}
function ReadMail(PlayerPawn p, String password) {
 local String squishedName;
 local int i;
 local int count;
 squishedName = squishString(p.GetHumanName());
 count = 0;
 for (i=0;i<4096;i++) {
  if (mailTo[i]!="" && StrContains(squishedName,squishString(mailTo[i]))) {
   count++;
   if (isPassworded(mailTo[i]) && !(getPassword(mailTo[i]) ~= password)) {
    p.ClientMessage("Please provide correct password for account "$mailTo[i]$".");
    continue;
   }
   // Display message:
   // p.ClientMessage(mailFrom[i] $ " -> " $ mailTo[i] $ " @ " $ mailDate[i] $ ": " $ mailMessage[i]);
   // p.ClientMessage("From " $ mailFrom[i] $ " to " $ mailTo[i] $ " at " $ mailDate[i] $ ": " $ mailMessage[i]);
   p.ClientMessage("From " $ mailFrom[i] $ " to " $ mailTo[i] $ " at " $ mailDate[i] $ ":");
   p.ClientMessage("  " $ mailMessage[i]);

   if (bSuggestReply && !(mailFrom[i] ~= "PostMaster")) {
    p.ClientMessage("Reply with: !mail "$squishString(mailFrom[i])$" <your_message>");
   }


   if (!isPassworded(mailTo[i]) && bRecommendPasswording) {
    p.ClientMessage("You can password the "$mailTo[i]$" account with: !setpass "$mailTo[i]$" <password>");
   }


   if (bSendConfirmationMessage && !(mailFrom[i] ~= "PostMaster")) {
    // Send a confirmation message back to the sender, saying their message was received (and by who).
    mailTo[i] = mailFrom[i];
    mailFrom[i] = "PostMaster";
    mailDate[i] = GetDate();
    // mailMessage[i] = ""$p.GetHumanName()$" received your message \""$mailMessage[i]$"\"";
    mailMessage[i] = ""$p.GetHumanName()$" received your message.";
   } else {
    // Clear message:
    mailFrom[i] = "";
    mailTo[i] = "";
    mailDate[i] = "";
    mailMessage[i] = "";
    // BUG TODO: If we don't shunt any later messages up to fill this gap at i, players may end up receiving messages in non-chronological order.
   }
   SaveConfig();
   CheckMailFor(p);
   return;

  }
 }

 if (count == 0) {
  p.ClientMessage("You have no new mail.");
 }
}


function bool isPassworded(String account) {
 return (getPassword(account) != "");
}

function String getPassword(String account) {
 local int i;
 for (i=0;i<2048;i++) {
  if (accountName[i]~=account) {
   return accountPass[i];
  }
 }
 return "";
}

function SetPass(PlayerPawn Sender, String account, String pass) {
 local String squishedNick;
 local int i;
 squishedNick = squishString(Sender.GetHumanName());
 account = squishString(account);
 if (Len(account) < 5) {
  Sender.ClientMessage("Accounts must contain at least 5 alphanumeric characters.");
 }
 if (StrContains(squishedNick,account)) {
  if (isPassworded(account)) {
   Sender.ClientMessage("Account "$account$" is already passworded.  Try: !changepass "$account$" <old_pass> <new_pass>");
  } else {
   for (i=0;i<2048;i++) {
    if (accountName[i]=="") {
     accountName[i] = account;
     accountPass[i] = pass;
     Sender.ClientMessage("Your account "$accountName[i]$" has been passworded.");
     break;
    }
   }
   // BUG: no handling if account database is full
   if (i == 2048) {
    Sender.ClientMessage("I'm sorry, there is no room for new accounts; please contact the server admin.");
   }
  }
 } else {
  Sender.ClientMessage("You may not password account "$account$" but you may password account "$squishedNick$".");
 }
}



function SendPrivateMessage(PlayerPawn Sender, String toNick, String message) {
 local PlayerPawn p;
 p = FindPlayerNamed(toNick);
 if (p == None) {
  Sender.ClientMessage("I could not find a player named "$toNick);
 } else {
  p.ClientMessage("Message from "$Sender.getHumanName()$": "$message);
  Sender.ClientMessage("Message sent to "$p.getHumanName());
  Sender.ClientMessage("To reply, say: !msg "$Sender.getHumanName()$" <your_message>");
 }
}

function PlayerPawn FindPlayerNamed(String name) {
 local PlayerPawn p;
 local PlayerPawn found;
 // for (p=Level.PawnList; p!=None; p=p.NextPawn) {
 foreach AllActors(class'PlayerPawn', p) {
  // if (p.IsA('PlayerPawn') || p.IsA('Bot')) {
   if (p.getHumanName() ~= name) { // exact case insensitive match, return player
    return p;
   }
   if (Instr(Caps(p.getHumanName()),Caps(name))>=0) { // partial match, remember it but keep searching for exact match
    found = p;
   }
  // }
 }
 return found; // return partial match, or None
}


// #include "/mnt/big/ut/ut_win/JLib/jlib.uc.jpp"
//===============//
//               //
//  JLib.uc.jpp  //
//               //
//===============//
function int SplitString(String str, String divider, out String parts[256]) {
 // local String parts[256];
 // local array<String> parts;
 local int i,nextSplit;
 i=0;
 while (true) {
  nextSplit = InStr(str,divider);
  if (nextSplit >= 0) {
   // parts.insert(i,1);
   parts[i] = Left(str,nextSplit);
   str = Mid(str,nextSplit+Len(divider));
   i++;
  } else {
   // parts.insert(i,1);
   parts[i] = str;
   i++;
   break;
  }
 }
 // return parts;
 return i;
}
function string GetDate() {
 local string Date, Time;
 Date = Level.Year$"/"$PrePad(Level.Month,"0",2)$"/"$PrePad(Level.Day,"0",2);
 Time = PrePad(Level.Hour,"0",2)$":"$PrePad(Level.Minute,"0",2)$":"$PrePad(Level.Second,"0",2);
 return Date$"-"$Time;
}
// NOTE: may cause an infinite loop if p=""
function string PrePad(coerce string s, string p, int i) {
 while (Len(s) < i)
  s = p$s;
 return s;
}
function bool StrStartsWith(string s, string x) {
 return (InStr(s,x) == 0);
 // return (Left(s,Len(x)) ~= x);
}
function bool StrEndsWith(string s, string x) {
 return (Right(s,Len(x)) ~= x);
}
function bool StrContains(String s, String x) {
 return (InStr(s,x) > -1);
}
function String StrAfter(String s, String x) {
 return StrAfterFirst(s,x);
}
function String StrAfterFirst(String s, String x) {
 local int i;
 i = Instr(s,x);
 return Mid(s,i+Len(x));
}
function string StrAfterLast(string s, string x) {
 local int i;
 i = InStr(s,x);
 if (i == -1) {
  return s;
 }
 while (i != -1) {
  s = Mid(s,i+Len(x));
  i = InStr(s,x);
 }
 return s;
}
function string StrBefore(string s, string x) {
 return StrBeforeFirst(s,x);
}
function string StrBeforeFirst(string s, string x) {
 local int i;
 i = InStr(s,x);
 if (i == -1) {
  return s;
 } else {
  return Left(s,i);
 }
}
function string StrBeforeLast(string s, string x) {
 local int i;
 i = InStrLast(s,x);
 if (i == -1) {
  return s;
 } else {
  return Left(s,i);
 }
}
function int InStrOff(string haystack, string needle, int offset) {
 local int instrRest;
 instrRest = InStr(Mid(haystack,offset),needle);
 if (instrRest == -1) {
  return instrRest;
 } else {
  return offset + instrRest;
 }
}
function int InStrLast(string haystack, string needle) {
 local int pos;
 local int posRest;
 pos = InStr(haystack,needle);
 if (pos == -1) {
  return -1;
 } else {
  posRest = InStrLast(Mid(haystack,pos+Len(needle)),needle);
  if (posRest == -1) {
   return pos;
  } else {
   return pos + Len(needle) + posRest;
  }
 }
}
// Converts a string to lower-case.
function String Locs(String in) {
 local String out;
 local int i;
 local int c;
 out = "";
 for (i=0;i<Len(in);i++) {
  c = Asc(Mid(in,i,1));
  if (c>=65 && c<=90) {
   c = c + 32;
  }
  out = out $ Chr(c);
 }
 return out;
}
// Will get all numbers from string.
// If breakAtFirst is set, will get first number, and place the remainder of the string in rest.
// Will accept all '.'s only leading '-'s
function String StrFilterNum(String in, optional bool breakAtFirst, optional out String rest) {
 local String out;
 local int i;
 local int c;
 local bool onNum;
 out = "";
 onNum = false;
 for (i=0;i<Len(in);i++) {
  c = Asc(Mid(in,i,1));
  if ( (c>=Asc("0") && c<=Asc("9")) || c==Asc(".") || (c==Asc("-") && !onNum) ) {
   out = out $ Chr(c);
   onNum = true;
  } else {
   if (onNum && breakAtFirst) {
    // onNum = false;
    // out = out $ " ";
    rest = Mid(in,i);
    return out;
   }
  }
 }
 rest = "";
 return out;
}
// UT2k4 had Repl(in,search,replace).
function String StrReplace(String in, String search, String replace) {
 local String out;
 local int i;
 out = "";
 for (i=0;i<Len(in);i++) {
  if (Mid(in,i,Len(search)) == search) {
   in = Left(in,i) $ replace $ Mid(in,i+Len(search));
   i = i - Len(search) + Len(replace);
  } else {
   out = out $ Mid(in,i,1);
  }
 }
 return out;
}
