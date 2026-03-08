#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

float rot;
vector axis;

default {
  state_entry() {
#ifdef NEG
    axis = <-1,0,0>;
#else
    axis = <1,0,0>;
#endif
    rot = TWO_PI/6;
    llTargetOmega(axis,0,0);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != WHEEL_ON &&
	chan != WHEEL_OFF) return;
    list params;
    switch (chan) {
    case WHEEL_ON: {
      llTargetOmega(axis,rot,1);
      break;
    }
    case WHEEL_OFF: {
      llTargetOmega(axis,0,0);
      break;
    }
    case WHEEL_SPEED: {
      float s = (float) msg;
      rot = TWO_PI / (s * 2);
      llTargetOmega(axis,rot,1);
      break;
    }
    default: break;
    }
    llSetLinkPrimitiveParamsFast(LINK_THIS, params);
  }
}    
