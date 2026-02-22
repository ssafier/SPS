#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef NAME
#define NAME "Ready"
#endif

string workout;
key lifter;

integer display_link;
integer initialized = FALSE;

initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;

  display_link = -1;
  while(currentLinkNumber <= objectPrimCount && display_link == -1) {
    //debug(currentLinkNumber);
    list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME]);
    //debug((string) params[0] + " " + (string) params[1]);
    if ((string) params[0] == "display") display_link = currentLinkNumber;
    ++currentLinkNumber;
  }
}

default {
  on_rez(integer x) {
    initialized = FALSE;
    initialize();
  }
  
  state_entry() {
    initialize();
    llSetClickAction(CLICK_ACTION_TOUCH);
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Weight : RackUI : 0, 0, 8, 1 : a=center;c=white;w=none");
      break;
    }
    default: {
      if (chan != setupRack &&
	  chan != testHudCheckPass &&
	  chan != testHudCheckFail) return;
      GET_CONTROL;
      switch (chan) {
      case testHudCheckPass: {  // initialize lifter
	llRequestExperiencePermissions(lifter, "");
	break;
      }
      case testHudCheckFail: {
	llRegionSayTo(lifter, 0, "Please wear the SPS HUD before working out.");
	lifter = NULL_KEY;
	break;
      }
      case setupRack: {
	debug("leaf "+msg);
	string popper;
	POP(workout);
	if (workout == "[RESET]" || workout == "[time out]") {
	  llMessageLinked(LINK_THIS, ResetEquipment, "", NULL_KEY);
	  llMessageLinked(LINK_THIS, 0," ", "fw_data: Weight");
	  llSetLinkPrimitiveParamsFast(display_link, [PRIM_TEXTURE, 0, "setup", <1,1,0>,ZERO_VECTOR,0]);
	  llMessageLinked(LINK_THIS, 0,"", "fw_data: Weight");
	  return;
	}
	PUSH(workout);
	llSetLinkPrimitiveParamsFast(display_link, [PRIM_TEXTURE, 0, "-"+workout, <1,1,0>,ZERO_VECTOR,0]);
	debug((string)next);
	NEXT_STATE;
	break;
      }
      default: break;
      }
      break;
    }
    }
  }
    
  experience_permissions(key avi) {
    llMessageLinked(LINK_SET, resetAnimationState, "", NULL_KEY);
    llMessageLinked(LINK_THIS,getPosForEquipment,
		    sSetupRack + "+" +
		    sInitializeLifter + "+" +
		    sConfigureEquipment + "+" +
		    sSitLifter +
		    "|<root node>",
		    avi);
  }

  experience_permissions_denied(key avi, integer r) {
    llSay(0, "The experience is necessary to play the game.");
    lifter = NULL_KEY;
  }
  
  touch_start(integer n) {
    integer link = llDetectedLinkNumber(0);
    list params = llGetLinkPrimitiveParams(link, [PRIM_NAME]);
    string name = (string) params[0];
    if (llSubStringIndex(name, "display") != -1 &&
	llDetectedTouchFace(0) == 0) {
      if (llAvatarOnLinkSitTarget(LINK_ROOT) == NULL_KEY) {
	llMessageLinked(LINK_THIS, testHudCheck, "", lifter = llDetectedKey(0));
	}
    }
  }
}
