#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

float rot;
vector axis;

default {
  state_entry() {
    axis = <1,0,0>;
    rot = TWO_PI/6;
    llTargetOmega(axis,0,0);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != HYDRAULIC_ON &&
	chan != HYDRAULIC_OFF) return;
    list params;
    switch (chan) {
    case HYDRAULIC_ON: {
      float r = 1.0/5;
      switch
      llSetTextureAnim(
		       ALL_SIDES,
		       ANIM_ON | LOOP | PING_PONG | ROT_WRAP, // Mode flags: ON, Loop continuously, Ping-Pong (smooth reverse), Wrap the rotation
		       1, // Number of frames (1 for continuous rotation)
		       1.0, // Speed (not used for continuous rotation mode)
		       0, // Start frame
		       r, // Rotation rate (revolutions per second)
		       0.0 // Rotation start
		       ); 
      break;
    }
    case HYDRAULIC_OFF: {
      llTargetOmega(axis,0,0);
      break;
    }
    default: break;
    }
    llSetLinkPrimitiveParamsFast(LINK_THIS, params);
  }
}    
