#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key lifter;
integer lifter_link;

integer rtf;
float orm_percent;
integer rep;
string animation;

integer terminal;
string level;

integer cache;
float end_time;
float time;

// cached values
float next_time;
string next_level;
integer next_terminal;
integer next_rep;

default {
  state_entry() {
    next_terminal = terminal = cache = FALSE;
    next_level = level = "";
    next_time = end_time = 0;
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != Lifting &&
	chan != stopLifting &&
	chan != returnRep &&
	chan != cacheRep) return;
    GET_CONTROL;
    string p;
    switch (chan) {
    case stopLifting: {
      llSetTimerEvent(0);
      lifter_link = -1;
      break;
    }
    case Lifting: {
      llResetTime();
      next_terminal = terminal = cache = FALSE;
      next_level = level = "";
      next_time = end_time = 0;
      lifter = xyzzy;
      POP(animation);
      POP(p);
      rtf = (integer) p;
      POP(p);
      orm_percent = (float) p;
      POP(p);
      lifter_link = (integer) p;
      terminal = FALSE;
      // NOTE: when rep is 1, getRep should calculate RIR
      // start base animation
      llMessageLinked(LINK_THIS, animateWithSpotter,
		      "|" + animation + "|" + (string) (afReplace | afCache), lifter);
      llMessageLinked(LINK_THIS, getRep, sReturnRep + "|" +
		      (string)(rep = 1) +  "|" + (string) rtf + "|" + (string) orm_percent,
		      lifter);
      llRequestExperiencePermissions(lifter, "");
      break;
    }
    case returnRep: {
      // anim: 1 easy, 2 med, 3 hard, 4 failing, 5 failed
      // time
      // terminal
      POP(level);
      debug("level "+ level);
      string p;
      POP(p);
      time = (float) p;
      debug("time "+ (string) time);
      POP(p);
      terminal = (integer) p | terminal;
      debug("terminal "+ (string) terminal);
      llMessageLinked(LINK_THIS,
		      animateWithSpotter, "|" + animation + " " + level + "|0", xyzzy);
      cache = TRUE;
      end_time = llGetTime() + time + 0.125;
      llSetTimerEvent(0.1);
      break;
    }
    case cacheRep: {
      POP(next_level);
      string p;
      POP(p);
      next_time = (float) p;
      POP(p);
      next_terminal = (integer) p | next_terminal;
      break;
    }
    default: break;
    }
  }

  state_exit() {
    llReleaseControls();
  }
  
  experience_permissions(key avi) {
    llRegionSayTo(avi, 0,"Use arrows to pose, PAGE UP to stop workout.");
    llTakeControls(
		   CONTROL_UP | CONTROL_DOWN |
		   CONTROL_LEFT | CONTROL_RIGHT |
		   CONTROL_FWD | CONTROL_BACK,
		   TRUE, FALSE);
  }

      
// Events for keyboard control
#define changing(x) change & x
#define up changing(CONTROL_UP)
#define down changing(CONTROL_DOWN)
#define fwd changing(CONTROL_FWD)
#define back changing(CONTROL_BACK)
#define rot_left changing(CONTROL_ROT_LEFT)
#define rot_right changing(CONTROL_ROT_RIGHT)
#define left changing(CONTROL_LEFT)
#define right changing(CONTROL_RIGHT)

#define holding(x) held & x
#define start_up holding(up)
#define start_down holding(down)
#define start_fwd holding(fwd)
#define start_back holding(back)
#define start_rot_left holding(rot_left)
#define start_rot_right holding(rot_right)
#define start_left holding(left)
#define start_right holding(right)

#define end_up (held == 0) && (up)
#define end_down (held == 0) && (down)
#define end_fwd (held == 0) && (fwd)
#define end_back (held == 0) && (back)
#define end_rot_left (held == 0) && (rot_left)
#define end_rot_right (held == 0) && (rot_right)
#define end_left (held == 0) && (left)
#define end_right (held == 0) && (right)

#define edge change == 0
#define cont_up (edge) && (holding(CONTROL_UP))
#define cont_down (edge) && (holding(CONTROL_DOWN))
#define cont_fwd (edge) && (holding(CONTROL_FWD))
#define cont_back (edge) && (holding(CONTROL_BACK))
#define cont_rot_left (edge) && (holding(CONTROL_ROT_LEFT))
#define cont_rot_right (edge) && (holding(CONTROL_ROT_RIGHT))
#define cont_left (edge) && (holding(CONTROL_LEFT))
#define cont_right (edge) && (holding(CONTROL_RIGHT))
  
  control(key id, integer held, integer change) {
    if (start_up) {
      next_terminal = TRUE;
      llReleaseControls();
      return;
    }
    vector offset = ZERO_VECTOR;
    if ((start_fwd) || (cont_fwd)) {
      offset = <0,0,0.01>;
    } else if ((start_back) || (cont_back)) {
      offset = <0,0,-0.01>;
    } else if ((start_left) || (cont_left)) {
      offset = <0,-0.01,0>;
    } else if ((start_right) || (cont_right)) {
      offset = <0,0.01,0>;
    }
    if (offset != ZERO_VECTOR) {
      llMessageLinked(LINK_THIS,incrementLifterPos, "|" + (string) offset, lifter);
    }
  }
  
  timer() {
    llSetTimerEvent(0);
    float now = llGetTime();
       
    if (terminal == FALSE) {
      if (cache) {
	next_rep = rep + 1;
	llMessageLinked(LINK_THIS, getRep, sCacheRep + "|" +
			(string) next_rep +  "|" + (string) rtf + "|" + (string) orm_percent,
			lifter);
	cache = FALSE;
      }
      terminal = next_terminal;
      if (terminal == FALSE && end_time <= now) {
	level = next_level;
	time = next_time;
	cache = TRUE;
	rep = next_rep;
	llMessageLinked(LINK_THIS,
			animateWithSpotter, "|" + animation + " " + level+"|0", lifter);
	end_time = now + time + 0.25;
      }
      llSetTimerEvent(0.1);
    } else if (end_time <= now) {
      llMessageLinked(LINK_THIS, publishSet,  sLiftingDone + "|" +
		      (string) rep +  "|" + (string) rtf + "|" + (string) orm_percent + "|" + level,
		      lifter);
    } else {
      float t = end_time - now;
      if (t <= 0) t = 0.1;
      llSetTimerEvent(t);
    }
  }
  
  changed(integer f) {
    if (f & CHANGED_LINK) {
      key l;
      // BUG, not guaranteed to succeed.
      if (lifter_link != -1 &&
	  (llAvatarOnSitTarget() == NULL_KEY ||
	   llGetLinkKey(lifter_link) == NULL_KEY ||
	   llAvatarOnLinkSitTarget(LINK_THIS) != llGetLinkKey(lifter_link))) {
	lifter = NULL_KEY;
	lifter_link = -1;
	llSetTimerEvent(0);
      }
    }
  }
}
