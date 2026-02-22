#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#define CLOCK 60.0 
#define WORKOUT_TIME 1800.0
#define FAT_CHANGE -0.05 / WORKOUT_TIME
#define INTEGRITY_CHANGE 0.02 / WORKOUT_TIME
#define FLEX_CHANGE 0.05 / WORKOUT_TIME

key yogi;
string animation;
float start_time;

#ifdef STRENGTH // probably for logs
#undef STRENGTH
#endif
#define STRENGTH 0
#define XP 1
#define FATIGUE 2
#define INJURED 3
#define WARMED_UP 4
#define RIR 5
#define MODIFIED 6

list arms_values;
list legs_values;
list chest_values;
list core_values;
list back_values;

float total_injury;
float total_fat;

integer link_num; // avatar
float fAdjust;
integer sitting = FALSE;

vector target = <0,0,1>;
vector offset = <0,0,0>;
rotation target_rot;

key request_key;
integer offset_dist = 1; // 5, 10, 25

integer channel;
integer handle;
integer yoga_channel;
#define SayToHud(x) if (yoga_channel != 0) llSay(yoga_channel, (string)(x))

integer initialized = FALSE;

// ------------------------------
init() {
  if (initialized) return;
  initialized = TRUE;
  target_rot = ZERO_ROTATION; //llEuler2Rot(<0,0,90>*DEG_TO_RAD);
  offset = <0,0,0>;
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

//----------------------------------
string values2Json(list v, float time) {
  float fat = (float) v[FATIGUE];
  float injured = (float) v[INJURED];
  integer result = FALSE;
  if (fat < 0.01) fat = 0.01;
  if (injured < 0) injured = 0;

  if (injured > 0) {
    injured -= (injured / total_injury) * INTEGRITY_CHANGE * time;
    if (injured < 0) injured = 0;
    result = TRUE;
  }
  if (fat > 0.01) {
    fat += ((fat - 0.01) / total_fat) * FAT_CHANGE * time;
    if (fat < 0.01) fat = 0.01;
    result = TRUE;
  }
  if (result) {
    return "{\"fatigue\":"+(string)fat+", "+
      "\"injured\":"+(string)injured+"}";
  } else
    return "";
}

//----------------------------------
string export2Json(key yogi, string record, string earned) {
  float time = llGetTime() - start_time;
  if (time > 1800) time = 1800;
  string output = "{\"yogi\": \""+(string) yogi + "\"," +
    " \"duration\": "+(string) time +
    ", \"flex\": "+(string) (FLEX_CHANGE * time);
  string temp = values2Json(arms_values, time);
  if (earned != "" && (integer) earned > 0) output = output + ", \"dollars\": "+earned;
  if (temp != "") output = output +  ", \"arms\": "+ temp;
  temp = values2Json(chest_values, time);
  if (temp != "") output = output + ", \"chest\": "+ temp;
  temp = values2Json(core_values, time);
  if (temp != "") output = output + ", \"core\": "+ temp;
  temp = values2Json(back_values, time);
  if (temp != "") output = output + ", \"back\": "+ temp;
  temp = values2Json(legs_values, time);
  if (temp != "") output = output + ", \"legs\": "+ temp;
  return output  + ", \"record\": " + record + "}";
}

// ---------------------------------------
list setBP(string json) {
  integer str = (integer)llJsonGetValue(json, ["strength"]);
  float xp = (float)llJsonGetValue(json, ["xp"]);
  float fat = (float)llJsonGetValue(json, ["fatigue"]);
  float injured = (float)llJsonGetValue(json, ["injured"]);
  integer warmedUp = (integer)llJsonGetValue(json,["warmed-up"]);
  if (fat < 0.01) fat = 0.01;
  
  total_injury += injured;
  total_fat +=(fat - 0.01);
  
  return [str, xp, fat, injured, warmedUp, 0.0, FALSE];
}

// ---------------------------------------
list updateBP(integer n, list bp, float tf, float ti, float time) {
  float fat = (float) bp[FATIGUE];
  float injured = (float) bp[INJURED];
  integer result = FALSE;
  if (fat < 0.01) fat = 0.01;
  if (injured < 0) injured = 0;

  if (injured > 0) {
    injured -= (injured / ti) * INTEGRITY_CHANGE * time;
    if (injured < 0) injured = 0;
    result = TRUE;
  }
  if (fat > 0.01) {
    fat += ((fat - 0.01) / tf) * FAT_CHANGE * time;
    if (fat < 0.01) fat = 0.01;
    result = TRUE;
  }
  if (result) return [(string) n + "+" + (string) fat + "+" + (string) injured]; else return [];
}

// ---------------------
default {
  state_entry() {
    init();
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  //SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    llSitTarget(target,target_rot);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != returnLeaf &&
	chan != Yoga &&
	chan != EndSession) return;
    GET_CONTROL;
    switch(chan) {
    case Yoga: {
      llRequestExperiencePermissions(yogi = xyzzy, "");
      break;
    }
    case EndSession: {
      string record;
      string earned;
      POP(earned);
      POP(record);
      debug(export2Json(xyzzy, record, earned));
      llMessageLinked(LINK_THIS, saveLifterStats,
		      "|yogaSession|" + export2Json(xyzzy, record, earned),
		      xyzzy);
      break;
    }
    case returnLeaf: {
      string s;
      POP(s);
      if (s != "STRING") return;
      POP(s);
      switch (s) {
      case "[End Class]": {
	llUnSit(yogi);
	break;
      }
      case "[time out]": break;
      default: {
	if (s != "" && s != animation) {
	  llStopAnimation(animation);
	  llStartAnimation(animation = s);
	  llMessageLinked(LINK_THIS, animateClass, animation, yogi);
	}
      }
      }
      break;
    }
    default: break;
    }
  }
  
  changed(integer f) {
    if (f & CHANGED_LINK &&
	yogi != NULL_KEY &&
	sitting) { /* &&  llAvatarOnSitTarget() == NULL_KEY) { */  // BUG -- does not return false on log out
      llReleaseControls();
      float time = llGetTime() - start_time;
      if (time > 60) {
	if (time > 1800) time = 1800;
	llMessageLinked(LINK_THIS, SaveLog, (string) saveClass + "+" + (string) EndSession + "|5|0|"+ (string)((FAT_CHANGE) * time) + "|" + (string) ALL_BODY_PARTS, yogi);
      }
      SayToHud("end|");
      llMessageLinked(LINK_THIS, endClass,"|", yogi);
      yoga_channel = 0;
      yogi = NULL_KEY;
      sitting = FALSE;
      llSetTimerEvent(0);
      llMessageLinked(LINK_THIS, ResetWorkout, "", NULL_KEY);
    }
  }
  
  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest != 1)  return;
    integer count = 0;
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

    llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
    checkUpdateSitTarget(target, target_rot);

    list anims = llGetAnimationList(yogi);
    integer len = llGetListLength(anims);
    while(len) {
      --len;
      string a = (string) anims[len];
      if (a != "" && (key) a != NULL_KEY) llStopAnimation((key) anims[len]);
    }
    llStartAnimation(animation = "Arm");
    llMessageLinked(LINK_THIS, checkClass, "|", yogi);
    debug("{\"player\": \""+(string) yogi + "\", \"type\":1}");
    request_key = llHTTPRequest(SERVER + "/sps/get/" + (string) yogi, [],"");
  }

  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != request_key) return;
    debug("http "+body);
    if (status != 200) {
      llSay(0, "Server error "+(string) status+".  Please try again.");
      llUnSit(yogi);
      return;
    }
    SayToHud("update|"+body);
    string armsV = llJsonGetValue(body,["arms"]);
    string chestV = llJsonGetValue(body,["chest"]);
    string coreV = llJsonGetValue(body,["core"]);
    string backV = llJsonGetValue(body,["back"]);
    string legsV = llJsonGetValue(body,["legs"]);
    string aerobic = llJsonGetValue(body,["aerobic"]);
    string flex = llJsonGetValue(body, ["flexibility"]);

    total_injury = 0;
    total_fat = 0;
 
    arms_values = setBP(armsV);
    chest_values = setBP(chestV);
    back_values = setBP(backV);
    core_values = setBP(coreV);
    legs_values = setBP(legsV);
    
    llMessageLinked(LINK_THIS, StartLog, "", NULL_KEY);
    yoga_channel = (integer)("0x"+ llGetSubString((string) yogi, -8, -1));
    SayToHud("yoga|1");

    sitting = TRUE;
    llRegionSayTo(yogi,0,"Use  arrows to adjust position.  Touch the mat for menu.");
    start_time = llGetTime();
    llShout(0, llGetDisplayName(yogi)+" is teaching a yoga class.");
    llSetTimerEvent(CLOCK);
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

  timer() {
    float time = llGetTime() - start_time;
    list result = [];
    debug("tick");
    result += updateBP(ARMS_BIT, arms_values, total_fat, total_injury, time);
    result += updateBP(BACK_BIT, back_values, total_fat, total_injury, time);
    result += updateBP(CORE_BIT, core_values, total_fat, total_injury, time);
    result += updateBP(CHEST_BIT, chest_values, total_fat, total_injury, time);
    result += updateBP(LEGS_BIT, legs_values, total_fat, total_injury, time);
    if (result != []) SayToHud("yoga-tick|" + (string) time + "|" + llDumpList2String(result,"|"));
    llMessageLinked(LINK_THIS, incrementClassPay, "|", yogi);
  }
}
