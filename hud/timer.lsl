#include "controlstack.h"
#include "evolve/sps.h"

integer running = FALSE;

default {
  state_entry() {
    if (running) llSetTimerEvent(15);
  }
  
  attach(key avi) {
    if (avi == NULL_KEY) {
      llSetTimerEvent(0);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != reStartClock  &&
	chan != StartClock &&
	chan != StopClock) return;
    switch (chan) {
    case StartClock: if (running) return;
    case reStartClock: {
      running = TRUE;
      llSetTimerEvent((float) msg);
      break;
    }
    case StopClock: {
      running = FALSE;
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTimerEvent(0);
    llMessageLinked(LINK_THIS, updateFromServer, "", NULL_KEY);
    llSetTimerEvent(1800);
  }
}
