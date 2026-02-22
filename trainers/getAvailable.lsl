#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

list trainers;
integer handle;
key server;

integer findAll(list a, list b) {
  integer l = llGetListLength(a);
  if (l != llGetListLength(b)) return FALSE;
  while (l > 0) {
    --l;
    if (llListFindList(b, [(key) a[l]]) == -1) return FALSE;
  }
  return TRUE;
}

default {
  state_entry() {
   handle = 0;
    llSetTimerEvent(1);
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);
  }
  sensor(integer ignore) {
    llSetTimerEvent(0);
    llSay(0,"Attached to trainer console.");
     // "SPS Trainer Console"
    handle = llListen(AvailableTrainerChannel, "[SPS] Trainer Console", llDetectedKey(0), "");
  }
 timer() {
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);
  }  
  listen(integer chan, string name, key xyzzy, string msg) {
    server = xyzzy;
    if (noTrainers(msg)) {
      debug("no trainers");
      trainers = [];
      llMessageLinked(LINK_SET, clearTrainers, name, xyzzy);
      return;
    }
    list newt = llParseString2List(msg, ["|"], []);
    if (findAll(newt, trainers) == 0) {
      trainers = newt;
      llMessageLinked(LINK_SET, registerTrainers, msg, xyzzy);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != getTrainer &&
	chan != trainerAvailable &&
	chan != testTrainerNotClient &&
	chan != disallowTrainer &&
	chan != testTrainer &&
	chan != menuTrainer) return;
    switch (chan) {
    case testTrainer: {
      debug(llDumpList2String(trainers," "));
      debug(xyzzy);
      if (llListFindList(trainers, [(string) xyzzy]) != -1)
	llMessageLinked(from, isTrainerPass, "|" + (string) xyzzy, xyzzy);	
      else
	llMessageLinked(from, isNotTrainer, "|" + (string) xyzzy, xyzzy);
      break;
    }
    case testTrainerNotClient: {
      if (llListFindList(trainers, [xyzzy]) == -1 || (llGetListLength(trainers) > 1)) 
	llMessageLinked(from, testTrainerNotClientPass, "|" + (string) xyzzy, xyzzy);
      else
	llMessageLinked(from, testTrainerNotClientFail, "|" + (string) xyzzy, xyzzy);	
      break;
    }
    case getTrainer: {
      string out;
      integer l = llGetListLength(trainers);
      integer i;
      for (i = 0; i < l; ++i) {
	if ((key) trainers[i] != xyzzy) {
	  if (out != "") out = out + "+";
	  out = out + ((string)(i+1)) + ") " +llGetDisplayName((key) trainers[i]);
	}
      }
      if (out == "") { llMessageLinked(LINK_THIS, setTrainerFail, "", xyzzy); return; }
      llSay(0, "here");
      llMessageLinked(LINK_THIS, doMenu, (string) menuTrainer +
		      "|Select Trainer|"+out, xyzzy);
      break;
    }
    case menuTrainer: {
      GET_CONTROL;
      string m;
      POP(m);
      integer i = llSubStringIndex(m,")");
      if (i == -1) return;
      i = (integer) llGetSubString(m,0,i-1)-1;
      PUSH((key) trainers[i]);
      PUSH(server);
      UPDATE_NEXT(checkTrainer);
      NEXT_STATE;
      break;
    }
    case disallowTrainer: {
      llRegionSayTo(server, TrainerQueryChannel, "disallow|"+msg);
      break;
    }
    case trainerAvailable: {
      llMessageLinked(LINK_THIS, freeTrainer, "|" + (string) server +"|" + msg, xyzzy);
      break;
    }
    default: break;
    }
  }
}
