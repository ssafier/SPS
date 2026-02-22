#include "controlstack.h"
#include "evolve/sps.h"

integer running = FALSE;

default {
  state_entry() {
    if (running) llSetTimerEvent(10);
  }

  attach(key avi) {
    if (avi == NULL_KEY) {
      llSetTimerEvent(0);
    }
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != startInfoClock  &&
	chan != stopInfoClock) return;
    switch (chan) {
    case startInfoClock: {
      if (running) return;
      running = TRUE;
      llSetTimerEvent(10);
      break;
    }
    case stopInfoClock: {
      running = FALSE;
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }
  }

  timer() {
    llMessageLinked(LINK_THIS, infoTick, "", NULL_KEY);
  }
}
