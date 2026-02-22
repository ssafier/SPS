#include "controlstack.h"
#include "evolve/sps.h"

#define cScanTime 5
#define nextState checkVisitors
#define controlData(s)  (string) setTrainers + "|"+s

#ifndef debug
#define debug(x)
#endif

integer handle;

default {
  state_entry() {
    llSetTimerEvent(cScanTime);
  }

  state_exit() {
    llSetTimerEvent(0);
  }

  timer() {
    debug("sensing");
    list area = llGetAgentList(AGENT_LIST_PARCEL, []);
    integer num = llGetListLength(area);
    debug(num);
    if (num == 0) {
      llMessageLinked(LINK_THIS, noAgents, "", NULL_KEY);
      return;
    } else {
      debug("calling check "+(string) nextState);
      llMessageLinked(LINK_THIS,
		      nextState,
		      controlData(llDumpList2String(area,"~")), NULL_KEY);
    }
    llSetTimerEvent(cScanTime);
  }
}
