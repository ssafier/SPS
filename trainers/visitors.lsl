#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

// locals
integer numAvatars = 0;

integer priorCount = 0;
list priorVisitorsKeys = [];
list currentVisitorsKeys = [];
list newKeys = [];
list departedKeys = [];

integer initp = FALSE;

integer find(list l, key t) {
  integer i;
  integer len = llGetListLength(l);
  for (i = 0; i < len; ++i)
    if ((key) l[i] == t) return TRUE; 
  return FALSE;
}

initVars() {
  priorCount = llGetListLength(priorVisitorsKeys  = currentVisitorsKeys);
  currentVisitorsKeys = [];
  departedKeys = [];
  newKeys = [];
}

// scan the region and update game scripts of players in region.
initializeAgents(list avatarsInRegion) {
  numAvatars = llGetListLength(avatarsInRegion);
  debug("num visitors "+(string)numAvatars);
  // if no avatars, abort avatar listing process and give a short notice
  if (!numAvatars)  {
    return;
  }
  
  integer index = 0;
  while (index < numAvatars) {
    key id = (key) avatarsInRegion[index];

    // assume if reboot, nobody arrived
    if (find(priorVisitorsKeys, id) == FALSE) { // no new visitors if initializing
      newKeys += id;
    }

    currentVisitorsKeys += id;
    ++index;
  }
  index = 0;
  debug("prior count "+(string)priorCount);
  while (index < priorCount) {
    key id = (key) priorVisitorsKeys[index];

    if (find(avatarsInRegion, id) == FALSE) { // no new visitors if initializing
      departedKeys += id;
    }
    ++index;
  }
}

// ----------------
default {
  on_rez(integer foo) {
    llResetScript();
  }

  state_entry() {
    priorVisitorsKeys = [];
    newKeys = [];
    departedKeys = [];
    priorCount = 0;
  }

  link_message(integer from, integer channel, string msg, key xyzzy) {
    if (channel != checkVisitors && channel != noAgents) return;
    GET_CONTROL;
    switch(channel) {
    case checkVisitors: {
      debug(msg);
      initVars();
      POP(msg);
      debug(msg);
      // creates the set of new agents in area
      initializeAgents(llParseString2List(msg, ["~"], []));
      debug("new key "+ (string)llGetListLength(newKeys));
      debug("departed key "+ (string)llGetListLength(departedKeys));
      debug("current key "+ (string)llGetListLength(currentVisitorsKeys));
#ifdef REPORT_NO_CHANGE
      if (newKeys == [] && departedKeys == []) {
	llMessageLinked(LINK_THIS, noChange,seq + "|" + data, xyzzy);
	return;
      }
#endif
      if (newKeys == []) newKeys = [NULL_KEY];
      if (departedKeys == []) departedKeys = [NULL_KEY];
      PUSH(llDumpList2String(departedKeys, "~"));
      PUSH(llDumpList2String(newKeys, "~"));
      PUSH(llDumpList2String(currentVisitorsKeys, "~"));
      break;
    } 
    case noAgents: {
      priorCount = 0;
      PUSH(llDumpList2String(currentVisitorsKeys, "~"));
      PUSH(llDumpList2String([NULL_KEY], "~"));
      PUSH(llDumpList2String([NULL_KEY], "~"));
      priorVisitorsKeys = [];
      currentVisitorsKeys = [];
      newKeys = [];
      departedKeys = [];
      if (next == 0) next = 100;
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
  
  state_exit() {
    llResetScript();
  }
}
