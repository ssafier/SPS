#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef showOffset
#define showOffset(x)
#endif

integer link_num;
float fAdjust;
rotation localrot;
vector localpos;

key sitter_2;

vector target = <0,0,0.3>;
vector offset = <0,0,0>;
rotation target_rot = ZERO_ROTATION;

integer handle;
integer offset_dist = 1; // 5, 10, 25

// ---------------------------------------

updateSitTarget(vector pos, rotation rot) {
  llLinkSitTarget(LINK_THIS, pos, rot);
  llSetLinkPrimitiveParamsFast(link_num,
			       [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
				PRIM_ROT_LOCAL, rot * localrot]);
}


// ---------------------------------------

checkUpdateSitTarget(vector t, rotation r) {
  if (t != target || r != target_rot) updateSitTarget(target = t + offset, target_rot = r);
}

// ---------------------------------------

default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    target = <-0.05000, -0.25000, 0.30000>;
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  //SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    llLinkSitTarget(LINK_THIS, target + offset, ZERO_ROTATION);
    offset = ZERO_VECTOR; 
  }

  touch_start(integer x) {
    if (llDetectedLinkNumber(0) != llGetLinkNumber()) return;
    key toucher = llDetectedKey(0);
    if (toucher == sitter_2 || toucher == llAvatarOnLinkSitTarget(LINK_ROOT))
      llMessageLinked(LINK_ROOT, getLeaf, (string) returnLeaf + "|<root node>", toucher);
  }

  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest == 1) {
      integer count = 0;
      if (llAvatarOnLinkSitTarget(LINK_THIS) == NULL_KEY) {
	llMessageLinked(LINK_SET, signalReset, "", sitter_2);
	return;
      }	
      sitter_2 = avi;
      vector size = llGetAgentSize(avi);
      fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
      integer linkNum = llGetNumberOfPrims();
      link_num = -1;
      while(linkNum && link_num == -1) {
	if (avi == llGetLinkKey(linkNum))
	  link_num = linkNum;
	else
	  --linkNum;
      }
      localrot = llGetLocalRot();
      localpos = llGetLocalPos();
      llRegionSayTo(sitter_2, 0, "Touch the table to change pose or to stand.");
      llMessageLinked(LINK_ROOT, bothSeated, "|" + (string) llGetLinkNumber(), sitter_2);
      llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
    } else {
      llInstantMessage(avi, "Cannot force agent " + (string)avi + " to sit due to reason id: " + (string)sitTest);
      llMessageLinked(LINK_SET, signalReset, "", sitter_2);
    }
  }

  experience_permissions_denied(key avi, integer reason) {
    llMessageLinked(LINK_SET, signalReset, "", sitter_2);
  }
    
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if ((chan != positionSitter2 &&
	 chan != resetTable &&
	 chan != initializeSitter) ||
	sitter_2 == NULL_KEY) return;
    GET_CONTROL;
    switch(chan) {
    case resetTable: {
      key k = sitter_2;
      sitter_2 = NULL_KEY;
      if (k != NULL_KEY) llUnSit(k);
      llReleaseControls();
      llResetScript();
      break;
    }
    case initializeSitter: {
      llRequestExperiencePermissions(xyzzy,"");
      break;
    }
    case positionSitter2: {
      string pos;
      string rot;
      
      POP(pos);
      POP(rot);
      debug(rot);
      checkUpdateSitTarget((vector) pos, (rotation) rot);
      break;
    }
    default: break;
    }
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
    debug((string) held + " " + (string) change);
    // do actual action depending on movement keys
    if ((start_down) || (cont_down)) {
      offset = offset - <0,0,0.01>;
    } else if ((start_up) || (cont_up)) {
      offset = offset + <0,0,0.01>;
    } else if ((start_fwd) || (cont_fwd)) {
      offset = offset + <0.01,0,0>;
    } else if ((start_back)  || (cont_back)) {
      offset = offset - <0.01,0,0>;
    } else if ((start_left) || (cont_left)) {
      offset = offset - <0,0.01,0>;
    } else if ((start_right)  || (cont_right)) {
      offset = offset + <0,0.01,0>;
    }
    updateSitTarget(target+offset, target_rot);
  }
}

