#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

float start;

default {
  state_entry() { start = 0; }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan < 300 || chan > 302) return;
    switch(chan) {
    case StartLog: {
      start = llGetTime();
      break;
    }
    case SaveLog: {
      GET_CONTROL;
      string type;
      POP(type);
      float duration = llGetTime() - start;
      string xp;
      POP(xp);
      string fatigue;
      POP(fatigue);
      string bp;
      POP(bp);
      PUSH("{\"type\": " + type + ", \"duration\":" + (string) ((integer)(duration+0.5)) +
	   ", \"xp\":" + xp + ", \"fatigue\":" + fatigue + ", \"bp\":" + bp + "}");
      NEXT_STATE;
    }
    case ResetLog: {
      start = 0;
      break;
    }
    default: break;
    }
  }
}
