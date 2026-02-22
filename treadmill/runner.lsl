#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef showOffset
#define showOffset(x)
#endif

key runner;
string animation;

integer link_num; // avatar
float fAdjust;
integer sitting = FALSE;

integer base;
integer roller;
list displays;

vector target = <0,0,0.1>;
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
  target_rot = llEuler2Rot(<0,0,-90>*DEG_TO_RAD);
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  list params= llGetLinkPrimitiveParams(LINK_THIS, [PRIM_DESC]);
  string desc = (string) params[0];
  displays = [];
  base = roller = -1;
  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME]);
    switch ((string) params[0]) {
    case "[SPS] Treadmill": {
      base = currentLinkNumber;
      break;
    }
    case "roller": {
      roller = currentLinkNumber;
      break;
    }
    case "display": {
      displays += [currentLinkNumber];
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
  offset = ZERO_VECTOR; 
  target = <0,0,0.7>;
  offset = <0,0,0>;
  target_rot = llEuler2Rot(<0,0,180>*DEG_TO_RAD);
}

// ---------------------------------------
updateSitTarget(vector pos, rotation rot) {
  debug((string) pos + " " + (string) rot);
  llSitTarget(pos, rot);
  llSetLinkPrimitiveParamsFast(link_num,
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
    llSitTarget(target,target_rot);
  }

  touch_start(integer x) {
    debug("touch");
    if (llAvatarOnSitTarget() == NULL_KEY) {
      debug("do test");
      sitting = FALSE;
      llMessageLinked(LINK_THIS, testHudCheck, "", runner = llDetectedKey(0));
    } 
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != returnLeaf &&
	chan != testHudCheckPass &&
	chan != testHudCheckFail &&
	chan != SetTreadmill &&
	chan != SetSpeedAnimation) return;
    switch(chan) {
    case SetSpeedAnimation: {
      if (animation != "") llStopAnimation(animation);
      llStartAnimation(animation = msg);
      break;
    }
    case SetTreadmill: {
      llRegionSayTo(runner,0,"Use  arrows to adjust position.  Use menu to stand.  Touch rails to change speed and resistance (wattage).");
      llMessageLinked(LINK_SET, activateButtons, "", runner);
      break;
    }
    case testHudCheckPass: {
      debug("pass");
      if (llAgentInExperience(runner)) {
	llListenControl(handle, TRUE);
	llDialog(runner, "Do you you want to workout on the treadmill?",
		 ["Yes", "No"], channel);
	llSetTimerEvent(20);
      } else {
	llRegionSayTo(runner, 0, "You must be a member of the SPS experience to use the treadmill.");
	runner = NULL_KEY;
      }
      break;
    }
    case testHudCheckFail: {
    runner = NULL_KEY;
      llSay(0, "Please wear the SPS HUD.");
      break;
    }
    default: break;
    }
  }

  changed(integer f) {
    if (f & CHANGED_LINK &&
	runner != NULL_KEY &&
	sitting) { /* &&  llAvatarOnSitTarget() == NULL_KEY) { */  // BUG -- does not return false on log out
	  llMessageLinked(LINK_SET, HYDRAULIC_OFF, "", NULL_KEY);
	  llReleaseControls();
	  llMessageLinked(LINK_SET, deactivateButtons, "", runner);
	  llSetLinkTextureAnim(roller, FALSE, ALL_SIDES, 1, 1, 1, 1, 0.2);
	  llMessageLinked(LINK_THIS,0, "0:00:00", "fw_data:Time");
	  llMessageLinked(LINK_THIS,0, "0 kM/H", "fw_data:Speed");
	  llMessageLinked(LINK_THIS,0, "0 W", "fw_data:Power");
	  llMessageLinked(LINK_THIS,0, "0 BPM", "fw_data:Heart");
	  llMessageLinked(LINK_THIS,0,"Treadmill","fw_data:Label");
	  llMessageLinked(LINK_THIS, publishSet, "|treadmill|", runner);
	  llSay((integer)("0x"+ llGetSubString((string) runner, -8, -1)),"reset|");
	  runner = NULL_KEY;
	  sitting = FALSE;
    }
  }

  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest != 1)  return;
    integer count = 0;
    llMessageLinked(LINK_THIS,0, llGetDisplayName(avi), "fw_data:Label");
    vector size = llGetAgentSize(avi);
    fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
    integer linkNum = llGetNumberOfPrims();
    link_num = -1;
    while(linkNum > 0 && link_num == -1) {
      if (avi == llGetLinkKey(linkNum))
	link_num = linkNum;
      else
	--linkNum;
    }
    if (link_num == -1) llSay(0,"Can't find avatar.");
    llMessageLinked(LINK_THIS, disallowTrainer, (string) avi, avi);
    llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
    checkUpdateSitTarget(target, target_rot);
    debug("{\"player\": \""+(string) runner + "\", \"type\":1}");

    list anims = llGetAnimationList(runner);
    integer len = llGetListLength(anims);
    while(len) {
      --len;
      string a = (string) anims[len];
      if (a != "" && (key) a != NULL_KEY) llStopAnimation((key) anims[len]);
    }

    debug("{\"player\": \""+(string) runner + "\", \"type\":1}");
    request_key = llHTTPRequest(SERVER + "/sps/initialize-cardio",
				[HTTP_MIMETYPE, "application/json", HTTP_METHOD, "POST"],
				"{\"player\": \""+(string) runner + "\", \"type\":1}");
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
    llMessageLinked(LINK_THIS, StartLog, "", runner);
    llMessageLinked(LINK_SET, HYDRAULIC_ON, "", NULL_KEY);
    sitting = TRUE;
    llMessageLinked(LINK_THIS,
		    InitializeWorkout,
		    (string) SetTreadmill + "|" +
		    (string) fatigue + "|"+ (string) cardioF + "|" + (string) max_intensity,
		    runner);
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
    if (msg == "Yes") llRequestExperiencePermissions(runner, "");
  }

  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    runner = NULL_KEY;
  }
}


