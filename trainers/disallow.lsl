#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer handle;
key server;

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
    llListenRemove(handle);
    handle = 0;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != disallowTrainer) return;
    switch (chan) {
    case disallowTrainer: {
      llRegionSayTo(server, TrainerQueryChannel, "disallow|"+msg);
      break;
    }
    default: break;
    }
  }
}
