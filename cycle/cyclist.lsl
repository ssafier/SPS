#include "include/controlstack.h"
#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef showOffset
#define showOffset(x)
#endif

key cyclist;
string animation;

integer cyclist_link; // avatar
float fAdjust;
integer sitting = FALSE;

integer seat;

vector target = <0,0.75,1.25>;
vector offset = <0,0,0>;
rotation target_rot;

float fatigue;
float cardioF;
integer max_intensity;

integer channel;
integer handle;
key request_key;
integer offset_dist = 1; // 5, 10, 25

integer initialized = FALSE;

// ------------------------------
init() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  list params= llGetLinkPrimitiveParams(LINK_THIS, [PRIM_DESC]);
  string desc = (string) params[0];
  seat = -1;
  target_rot = llEuler2Rot(<0,0,270>*DEG_TO_RAD);
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


// ---------------------------------------
updateSitTarget(vector pos, rotation rot) {
  debug((string) pos + " " + (string) rot);
  llLinkSitTarget(seat, pos, rot);
  llSetLinkPrimitiveParamsFast(cyclist_link,
			       [PRIM_POS_LOCAL, pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust),
			       PRIM_ROT_LOCAL, rot]);
}


// ---------------------------------------
checkUpdateSitTarget(vector t, rotation r) {
  if (t != target || r != target_rot) updateSitTarget(target = t + offset, target_rot = r);
}

// ---------------------
default {
  state_entry() {
    init();
    llSetClickAction(CLICK_ACTION_TOUCH);
    channel = (integer)("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  //SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    llLinkSitTarget(seat, target,target_rot);
  }

  touch_start(integer x) {
    debug("touch");
    if (llAvatarOnLinkSitTarget(seat) == NULL_KEY) {
      debug("do test");
      sitting = FALSE;
      llMessageLinked(LINK_THIS, testHudCheck, "", cyclist = llDetectedKey(0));
    } 
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != returnLeaf &&
	chan != testHudCheckPass &&
	chan != testHudCheckFail &&
	chan != SetCycle &&
	chan != SetSpeedAnimation) return;
    switch(chan) {
    case SetSpeedAnimation: {
      if (animation != "") llStopAnimation(animation);
      llStartAnimation(animation = msg);
      break;
    }
    case SetCycle: {
      //llRegionSayTo(cyclist,0,"Use  arrows to adjust position.  Use menu to stand.  Touch rails to change speed and resistance (wattage).");
      llMessageLinked(LINK_SET, activateButtons, "", cyclist);
      break;
    }
    case testHudCheckPass: {
      debug("pass");
      if (llAgentInExperience(cyclist)) {
	llListenControl(handle, TRUE);
	llDialog(cyclist, "Do you you want to workout on the bike?",
		 ["Yes", "No"], channel);
	llSetTimerEvent(20);
      } else {
	llRegionSayTo(cyclist, 0, "You must be a member of the SPS experience to use the bike.");
	cyclist = NULL_KEY;
      }
      break;
    }
    case testHudCheckFail: {
      cyclist = NULL_KEY;
      llSay(0, "Please wear the SPS HUD.");
      break;
    }
    case returnLeaf: {
      string s;
      GET_CONTROL;
      POP(s);
      if (s != "STRING") return;
      POP(s);
      if (s == "[STAND]") llUnSit(cyclist);
      NEXT_STATE;
      break;
    }
    default: break;
    }
  }

  changed(integer f) {
    if (f & CHANGED_LINK &&
	cyclist != NULL_KEY &&
	sitting &&
	(llAvatarOnLinkSitTarget(seat) == NULL_KEY ||
	 llGetLinkKey(cyclist_link) == NULL_KEY ||
	 llAvatarOnLinkSitTarget(seat) != llGetLinkKey(cyclist_link))) {
      llMessageLinked(LINK_SET, WHEEL_OFF, "", NULL_KEY);
      llReleaseControls();
      llMessageLinked(LINK_SET, deactivateButtons, "", cyclist);
      llMessageLinked(LINK_THIS,0, "0:00:00", "fw_data:Time");
      llMessageLinked(LINK_THIS,0, "0 kM/H", "fw_data:Speed");
      llMessageLinked(LINK_THIS,0, "0 W", "fw_data:Power");
      llMessageLinked(LINK_THIS,0, "0 BPM", "fw_data:Heart");
      llMessageLinked(LINK_THIS, publishSet, "|bike|", cyclist);
      llSay((integer)("0x"+ llGetSubString((string) cyclist, -8, -1)),"reset|");
      cyclist = NULL_KEY;
      sitting = FALSE;
    }
  }

  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, seat);
    if (sitTest != 1)  return;
    integer count = 0;
    vector size = llGetAgentSize(avi);
    fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
    integer linkNum = llGetNumberOfPrims();
    cyclist_link = -1;
    while(linkNum > 0 && cyclist_link == -1) {
      if (avi == llGetLinkKey(linkNum))
	cyclist_link = linkNum;
      else
	--linkNum;
    }
    if (cyclist_link == -1) llSay(0,"Can't find avatar.");
    llMessageLinked(LINK_THIS, disallowTrainer, (string) avi, avi);
    llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
    checkUpdateSitTarget(target, target_rot);
    debug("{\"player\": \""+(string) cyclist + "\", \"type\":1}");

    list anims = llGetAnimationList(cyclist);
    integer len = llGetListLength(anims);
    while(len) {
      --len;
      string a = (string) anims[len];
      if (a != "" && (key) a != NULL_KEY) llStopAnimation((key) anims[len]);
    }

    debug("{\"player\": \""+(string) cyclist + "\", \"type\":1}");
    request_key = llHTTPRequest(SERVER + "/sps/initialize-cardio",
				[HTTP_MIMETYPE, "application/json", HTTP_METHOD, "POST"],
				"{\"player\": \""+(string) cyclist + "\", \"type\":2}");
  }

  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != request_key) return;
    debug("http "+body);
    cardioF =(float) llJsonGetValue(body, ["cardioF"]);
    debug("c "+(string)cardioF);
    string legs = llJsonGetValue(body, ["legs"]);
    debug(llJsonGetValue(legs,["strength"]));
    fatigue = (float) llJsonGetValue(legs, ["fatigue"]);
    debug("fat "+(string)fatigue);
    max_intensity = ((integer) llJsonGetValue(legs,["strength"])) * 10;
    llMessageLinked(LINK_THIS, StartLog, "", cyclist);
    llMessageLinked(LINK_SET, HYDRAULIC_ON, "", NULL_KEY);
    sitting = TRUE;
    llMessageLinked(LINK_THIS,
		    InitializeWorkout,
		    (string) SetCycle + "|" +
		    (string) fatigue + "|"+ (string) cardioF + "|" + (string) max_intensity,
		    cyclist);
  }

  experience_permissions_denied(key avi, integer reason) {
    llRegionSayTo(avi, 0, "You must accepts SPS permissions to use this machine.");
  }
    
#include "include/takecontrol.h"
  
  control(key id, integer held, integer change) {
    debug((string) held + " " + (string) change);
    if ((start_fwd) || (cont_fwd)) {
      offset = offset + <0.,0,0.01>;
    } else if ((start_back)  || (cont_back)) {
      offset = offset - <0,0,0.01>;
    } else if ((start_left) || (cont_left)) {
      offset = offset - <0,0.01,0>;
    } else if ((start_right)  || (cont_right)) {
      offset = offset + <0,0.01,0>;
    }
    updateSitTarget(target+offset, target_rot);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    if (msg == "Yes") llRequestExperiencePermissions(cyclist, "");
  }

  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    cyclist = NULL_KEY;
  }
}


