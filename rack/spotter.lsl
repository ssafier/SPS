#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key spotter;
key spotter_prim;
integer spotter_link;

integer has_trainers;

string animation;

integer dollars;

integer initialized;

initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  spotter = spotter_prim = NULL_KEY;
  dollars = 0;
  spotter_link = -1;
  debug(objectPrimCount);
  while(currentLinkNumber <= objectPrimCount) {
    debug(currentLinkNumber);
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME, PRIM_DESC]);
    debug((string) params[0] + " " + (string) params[1]);
    switch((string) params[0]) {
    case "spotter prim": {
      spotter_prim = llGetLinkKey(spotter_link = currentLinkNumber);
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
  if (spotter_prim == NULL_KEY) {
    llSay(0, "Error: cannot find sitter prims");
  }
}

default {
  on_rez(integer param) {
    initialize();
  }

  state_entry() {
    initialize();
    spotter = NULL_KEY;
    dollars = 0;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == saveSpotter) {
      GET_CONTROL;
      string log;
      POP(log);
      string lifter;
      POP(lifter);       
      string json = "{\"lifter\": " + lifter + ", \"entry\": " + log;
      if (dollars > 0) {
	json = json +
	  ", \"spotter\": {\"lifter\": \""+(string) spotter + "\", \"dollars\": "+(string) dollars + "}";
      }
      llMessageLinked(LINK_THIS, saveLifterStats, "|record|" + json + "}", xyzzy);
      return;
    }
    if (chan != registerTrainers &&
	chan != clearTrainers &&
	chan != resetTrainer &&
	chan != setTrainer &&
	chan != publishSetForSpotter &&
	chan != animateWithSpotter &&
	chan != checkSpotterMenu) return;
    GET_CONTROL;
    switch (chan) {
    case animateWithSpotter: {
      string a;
      POP(a);
      string c;
      POP(c);
      debug("animate|" + (string) xyzzy + "|" + (string) spotter + "|" + a + "|" + c);
      
      llMessageLinked(LINK_THIS, doAnimations,
		      "animate|" + (string) xyzzy + "|" + (string) spotter + "|" + (animation = a) + "|" + c,
		      xyzzy);
      break;
    }
    case resetTrainer: {
      llMessageLinked(LINK_THIS, trainerAvailable, (string) spotter, spotter);
      llMessageLinked(spotter_link, resetTrainer,"", spotter);
      spotter = NULL_KEY;
      dollars = 0;
      break;
    }
    case publishSetForSpotter: {
      if (spotter != NULL_KEY) {
	integer spotter_channel = (integer)("0x"+ llGetSubString((string) spotter, -8, -1));
	llSay(spotter_channel, "pay|5");
	dollars += 5;
      }
      break;
    }
    case registerTrainers: {
      has_trainers = TRUE;
      break;
    }
    case clearTrainers: {
      has_trainers = FALSE;
      break;
    }
    case checkSpotterMenu: {
      if (has_trainers == TRUE && spotter == NULL_KEY) {
	PUSH("SpotAvail");
      } else {
	PUSH("Seated");
      }
      break;
    }
    case setTrainer: {
      debug("set trainer "+(string) xyzzy+" "+(string)spotter_link + " " + msg) ;
      spotter = xyzzy;  // trainer is xyzzy, lifter is msg
      key lifter = (key) llGetSubString(msg,1,-1);
      llMessageLinked(spotter_link, initializeSitter, "", spotter);
      debug("animate|" + (string) lifter + "|" + (string) spotter + "|" + animation + "|3");
      llMessageLinked(LINK_THIS, getLeaf, (string) returnIntensityLeaf + "|Seated", lifter);
      llSleep(0.5);
      llMessageLinked(LINK_THIS, doAnimations,
		      "animate|" + (string) lifter + "|" + (string) spotter + "|" + animation + "|3", 
		      lifter);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
}
