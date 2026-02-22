#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

float rot;
vector axis;

default {
  state_entry() {
#ifdef NEG
    axis = <0,-1,0>;
#else
    axis = <0,1,0>;
#endif
    rot = TWO_PI/6;
    llTargetOmega(axis,0,0);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != HYDRAULIC_ON &&
	chan != HYDRAULIC_OFF) return;
    list params;
    switch (chan) {
    case GEAR_ON: {
      llTargetOmega(axis,rot,1);
      break;
    }
    case GEAR_OFF: {
      llTargetOmega(axis,0,0);
      break;
    }
    case GEAR_SPEED: {
      float s = (float) msg;
      rot = TWO_PI / (s * 2);
      break;
    }
    default: break;
    }
    llSetLinkPrimitiveParamsFast(LINK_THIS, params);
  }
}    
