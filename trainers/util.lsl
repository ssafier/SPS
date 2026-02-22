#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer handle;
default {
  state_entry() {
    handle = llListen(TrainerResponseChannel, "[SPS] Trainer Console", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list cmd = llParseString2List(msg,["|"],[]);
    switch((string) cmd[0]) {
    case "ok": {
      llMessageLinked(LINK_THIS, setTrainer, "|" + (string) cmd[1], (key) cmd[2]);
      llSetTimerEvent(0);
      llListenControl(handle, FALSE);
      break;
    }
    case "error": {
      llMessageLinked(LINK_THIS, setTrainerFail, "|" + (string) cmd[1], (key) cmd[2]);
      llSetTimerEvent(0);
      llListenControl(handle, FALSE);
      break;
    }
    case "freed": 
    default: break;
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != checkTrainer &&
	chan != freeTrainer) return;
    GET_CONTROL;
    string server;
    POP(server);
    string trainer;
    POP(trainer);
    llSetTimerEvent(5);
    llListenControl(handle, TRUE);
    switch(chan) {
    case checkTrainer: {
      llRegionSayTo((key) server, TrainerQueryChannel, "assign|"+trainer+"|"+(string) xyzzy);
      break;
    }
    case freeTrainer: {
      llRegionSayTo((key) server, TrainerQueryChannel, "free|"+trainer);
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
  }
}
