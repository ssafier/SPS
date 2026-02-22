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
  on_rez(integer x) { llResetScript(); }
  state_entry() {
    handle = 0;
    llSetTimerEvent(1);
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);
  }
  sensor(integer ignore) {
    llSetTimerEvent(0);
    llSay(0,"Attached to trainer console.");
    handle = llListen(TrainerChannel, "[SPS] Trainer Console", llDetectedKey(0), "");    
  }
  timer() {
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    server = xyzzy;
    if (noTrainers(msg)) {
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
}
