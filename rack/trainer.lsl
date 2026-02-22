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

key trainer;

vector target = <0,0,0.3>;
vector offset = <0,0,0>;
rotation target_rot = ZERO_ROTATION;

integer handle;
string last_pos;
string last_rot;

// ---------------------------------------

updateSitTarget(vector pos, rotation rot) {
  llLinkSitTarget(LINK_THIS, pos, rot);
  llSetLinkPrimitiveParamsFast(link_num,
			       [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)),
				PRIM_ROT_LOCAL, rot]);
}


// ---------------------------------------

checkUpdateSitTarget(vector t, rotation r) {
  if (t != target || r != target_rot) updateSitTarget(target = t + offset, target_rot = r);
}

// ---------------------------------------

default {
  state_entry() {
    target = <-0.05000, -0.25000, 1.30000>;
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  //				  SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    llLinkSitTarget(LINK_THIS, target + offset, ZERO_ROTATION);
    fAdjust = 0;
    trainer = NULL_KEY;
    offset = ZERO_VECTOR; 
  }

  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest == 1) {
      integer count = 0;
      if (llAvatarOnLinkSitTarget(LINK_THIS) == NULL_KEY) {
	llMessageLinked(LINK_SET, signalReset, "", trainer);
	return;
      }	
      trainer = avi;
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
      updateSitTarget((vector) last_pos, (rotation) last_rot);
      llRegionSayTo(avi, 0, "Thank you for spotting.");
      llRegionSayTo(avi, 0, "PAGE UP to stand.  Use arrow keys to adjust your position.");
      llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
    } else {
      llInstantMessage(avi, "Cannot force agent " + (string)avi + " to sit due to reason id: " + (string)sitTest);
      llMessageLinked(LINK_SET, signalReset, "", trainer);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != positionSitter2 &&
	 chan != resetTrainer &&
	chan != initializeSitter) return;
    GET_CONTROL;
    switch(chan) {
    case resetTrainer: {
      if (trainer != NULL_KEY) {
	llUnSit(trainer);
	trainer = NULL_KEY;
	llReleaseControls();
      }
      llResetScript();
      break;
    }
    case initializeSitter: {
      debug("initialize sitter");
      llRequestExperiencePermissions(xyzzy,"");
      break;
    }
    case positionSitter2: {
      if (trainer == NULL_KEY) return;
      POP(last_pos);
      POP(last_rot);
      debug(last_pos);
      debug(last_rot);
      if (trainer != NULL_KEY) {
	checkUpdateSitTarget((vector) last_pos, (rotation) last_rot);
      } 
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
    } else if (start_up)  {
	llUnSit(trainer);
	trainer = NULL_KEY;
	llReleaseControls();
	return;
    } else if ((start_fwd) || (cont_fwd)) {
      offset = offset + <0,0,0.01>;
    } else if ((start_back)  || (cont_back)) {
      offset = offset - <0,0,0.01>;
    } else if ((start_left) || (cont_left)) {
      offset = offset - <0,0.01,0>;
    } else if ((start_right)  || (cont_right)) {
      offset = offset + <0,0.01,0>;
    }
    updateSitTarget(target+offset, target_rot);
  }
}

