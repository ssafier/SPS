#include "include/sps.h"
integer seat;
integer initialized = FALSE;

initialize() {
  if (initialized) return;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  list params= llGetLinkPrimitiveParams(LINK_THIS, [PRIM_DESC]);
  string desc = (string) params[0];
  seat = -1;
  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME]);
    switch ((string) params[0]) {
    case "Seat": {
      seat = currentLinkNumber;
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
}

default {
  on_rez(integer x) { initialize(); }
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    initialize();
  }

  touch_start(integer x) {
    vector point = llDetectedTouchUV(0);
    key user = llDetectedKey(0);
#ifdef REPORT
    llSay(0,(string)llDetectedTouchFace(0));
    llSay(0,(string)point);
#endif
    if (user != llAvatarOnLinkSitTarget(seat) ||
	point.y > 0.3 ||
	point.x < 0.225 ||
	point.x > 0.77) return;
    if (point.x < 0.269) {
      llMessageLinked(LINK_SET, SpeedDown, "1000", NULL_KEY);
    } else {
      if (point.x < 0.29) {
	llMessageLinked(LINK_SET, SetSpeed, "5000", NULL_KEY);
      } else {
	if (point.x < 0.33) {
	  llMessageLinked(LINK_SET, SetSpeed, "10000", NULL_KEY);
	} else {
	  if (point.x < 0.365) {
	    llMessageLinked(LINK_SET, SetSpeed, "15000", NULL_KEY);
	  } else {
	    if (point.x < 0.405) {
	      llMessageLinked(LINK_SET, SetSpeed, "20000", NULL_KEY);
	    } else {
	      if (point.x < 0.445) {
		llMessageLinked(LINK_SET, SetSpeed, "25000", NULL_KEY);
	      } else {
		if (point.x < 0.485) {
		  llMessageLinked(LINK_SET, SetSpeed, "30000", NULL_KEY);
		} else {
		  if (point.x < 0.525) {
		    llMessageLinked(LINK_SET, SetSpeed, "35000", NULL_KEY);
		  } else {
		    if (point.x < 0.565) {
		      llMessageLinked(LINK_SET, SetSpeed, "40000", NULL_KEY);
		    } else {
		      if (point.x < 0.605) {
			llMessageLinked(LINK_SET, SetSpeed, "45000", NULL_KEY);
		      } else {
			if (point.x < 0.645) {
			  llMessageLinked(LINK_SET, SetSpeed, "50000", NULL_KEY);
			} else {
			  if (point.x < 0.685) {
			    llMessageLinked(LINK_SET, SpeedUp, "1000", NULL_KEY);
			  } else {
			    llMessageLinked(LINK_SET, getLeaf, (string) returnLeaf + "|<root node>", user);
			  }}}}}}}}}}}}
  }
}

