#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

list trainers;
integer handle;
key yoga_class;
integer yoga_class_channel; // zero if no class is in session

// ----------------------
#define find(x, l) (llListFindList(l,[x]) != -1)

// ----------------------
string checkAvailability() {
  integer l = llGetListLength(trainers);
  list a = [];
  debug("trainers for avail "+llDumpList2String(trainers,"|"));
  while (l > 0) {
    l = l - 2;
    if ((key) trainers[l+1] == NULL_KEY) {
      a = [(key) trainers[l]] + a;
    }
  }
  debug("avail "+llDumpList2String(a,"|"));
  return llDumpList2String(a,"|");
}

updateRegion() {
  llRegionSay(TrainerChannel, llDumpList2String(llList2ListStrided(trainers,0,-1,2),"|"));
  llRegionSay(AvailableTrainerChannel,  checkAvailability());
}

integer empty(list l) {
  integer len = llGetListLength(l);
  return len == 0 || (len == 1 && ((key)(string)l[0]) == NULL_KEY);
}

removeTrainerFromList(key t) {
  integer i = llListFindList(trainers,[t]);
  if (i != -1) {
    if (i == 0) {
      if (llGetListLength(trainers) > 2)
	trainers = llList2List(trainers,2,-1);
      else
	trainers = [];
    } else {
      if ((i % 2) == 0) trainers = llDeleteSubList(trainers, i, i+1);
    }
  }
}

default {
  state_entry() {
    trainers = [];
    handle = llListen(TrainerQueryChannel,"",NULL_KEY, "");
    llListenControl(handle,FALSE);
    yoga_class = NULL_KEY;
    yoga_class_channel = 0;
    llSetTimerEvent(5);
  }

  timer() {
    updateRegion();
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != setTrainers &&
	chan != addTrainer &&
	chan != removeTrainer &&
	chan != noAgents) return;
    GET_CONTROL;
    switch(chan) {
    case setTrainers: {
      string avis;
      POP(avis);
      string D;
      POP(D);
      list newkeys = llParseStringKeepNulls(D,["~"],[]);
      POP(D);
      list gone = llParseStringKeepNulls(D,["~"],[]);
      if (empty(gone) && empty(newkeys)) return;

      list current = llParseStringKeepNulls(avis,["~"],[]);
      debug("old "+llDumpList2String(trainers, " "));
      debug("current "+msg);
      list newts = [];
      integer l = llGetListLength(trainers);
      debug("len "+(string)l);
      while(l > 0) {
	l = l -2;
	debug(((string) l)+" "+ ((string) (key) trainers[l]));
	debug(llListFindList(current,[(string) trainers[l]]));
	if (find((string) trainers[l], current))
	  newts = newts + [(key) trainers[l], (key) trainers[l+1]];
      }
      trainers = newts;
      debug("new "+llDumpList2String(trainers, " "));
      if (trainers == []) llListenControl(handle,FALSE);
      break;
    }
    case addTrainer: {
      string t;
      POP(t);
      if (trainers == []) llListenControl(handle,TRUE);
      if (llListFindList(trainers,[(key) t]) == -1)
	trainers = [(key) t, NULL_KEY] + trainers;
      break;
    }
    case removeTrainer: {
      string t;
      POP(t);
      removeTrainerFromList((key) t);
      if (trainers == []) llListenControl(handle,FALSE);
      break;
    }
    case noAgents: {
      if (trainers == []) return;
      trainers = [];
      llListenControl(handle,FALSE);
      break;
    }
    default: break;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    debug(msg);
    list cmd = llParseString2List(msg,["|"],[]);
    switch((string)cmd[0]) {
    case "assign": {
      integer i = llListFindList(trainers, [(key)(string)cmd[1]]);
      if (i == -1) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|no spotter|"+(string) cmd[1]);
	return;
      }
      if ((i & 1) == 1) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|trainee|"+(string) cmd[1]);
	return;
      }
      if ((key) trainers[i+1] != NULL_KEY) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|in use|"+(string) cmd[1]);
	return;
      }
      trainers = llListReplaceList(trainers, [(key) cmd[2]], i+1, i+1);
      removeTrainerFromList((key) cmd[2]);
      llRegionSayTo(xyzzy,TrainerResponseChannel, "ok|"+(string) cmd[2] + "|" + (string) cmd[1]);
      break;
    }
    case "disallow": {
      removeTrainerFromList((key) cmd[1]);
      if (trainers == []) llListenControl(handle,FALSE);
      break;
    }
    case "end-yoga-class": {
      yoga_class_channel = 0;
      // pass thru
    }
    case "free": {
      debug("free "+ (string)cmd[1]);
      integer i = llListFindList(trainers, [(key)(string)cmd[1]]);
      if (i == -1 || (i % 2) == 1) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|no spotter|"+(string) cmd[1]);
	return;
      }
      trainers = llListReplaceList(trainers, [NULL_KEY], i+1, i+1);
      llRegionSayTo(xyzzy, TrainerResponseChannel, "freed|");
      break;
    }
    case "display": {
      llRegionSayTo(xyzzy, TrainerResponseChannel, "tc|" + llDumpList2String(trainers,"|"));
      break;
    }
    case "get-yoga-class": {
      if (yoga_class != NULL_KEY) {
	llRegionSayTo(xyzzy, TrainerResponseChannel, "class|" + (string) yoga_class + "|" + (string) yoga_class_channel);
      } else {
	llRegionSayTo(xyzzy, TrainerResponseChannel, "no-class|");
      }
      break;
    }
    case "start-yoga-class": {
      string yogi = (string) cmd[1];
      integer i = llListFindList(trainers, [(key) yogi]);
      
      if (i == -1) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|no trainer|"+(string) cmd[1]);
	return;
      }
      if ((i & 1) == 1) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|trainee|"+(string) cmd[1]);
	return;
      }
      if ((key) trainers[i+1] != NULL_KEY) {
	llRegionSayTo(xyzzy,TrainerResponseChannel, "error|in use|"+(string) cmd[1]);
	return;
      }
      
      if (yoga_class == NULL_KEY) { yoga_class = xyzzy; }
      yoga_class_channel = (integer)("0x"+llGetSubString(yogi, -3,-1)+
				     llGetSubString((string) yoga_class, -3, -1)+
				     llGetSubString((string) llGetKey(), -2, -1));
      llRegionSayTo(yoga_class,
		    TrainerResponseChannel, "class|" + (string) yoga_class + "|" + (string) yoga_class_channel);
      trainers = llListReplaceList(trainers, [(key) "Yoga"], i+1, i+1);
      llRegionSayTo(xyzzy,TrainerResponseChannel, "ok|"+(string) cmd[2] + "|" + (string) cmd[1]);
      break;
    }
    case "assign-class-yoga-mat": {
      yoga_class = (key) (string) cmd[1];
      break;
    }
    default: break;
    }
  }
}

       
