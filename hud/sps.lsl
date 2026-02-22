#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#define UPDATE_TIMER 10
#define VERSION_NUM VERSION

integer initialized = FALSE;
  
// hud construction
integer arms_prim;
integer legs_prim;
integer chest_prim;
integer core_prim;
integer back_prim;
integer arms_status;
integer legs_status;
integer chest_status;
integer core_status;
integer back_status;

// data
list arms_values;
list legs_values;
list chest_values;
list core_values;
list back_values;

integer trainer_dollars;
float flexibility;
float aerobic;

// strided list of supplement name and id
list supplements;
list messages;

integer info_index;

// user data
integer channel;
integer handle;
key user;

// working out
integer machine_channel;
integer machine_workout;
key machine;
integer recovering = FALSE;

// server
key http_handle;

//----------------------------------
integer active(integer s) {
  integer l = llGetListLength(supplements);
  integer i;
  for(i = 1; i < l; i += 2) {
    if ((integer)(string)supplements[i] == s) return TRUE;
  }
  return FALSE;
}

//----------------------------------
vector getColor(float fat, float inj) {
  if (fat <= 0.01 && inj <0.01) return <1,1,1>;
  vector color = ZERO_VECTOR;
  if (fat > 0.01) {
    color.x = 1.0;
    if ((color.y = 1.0 - fat) < 0) color.y = 0;
  }
  if (inj > 0.01) {
    color.z = inj;
    if (color.y > 0) {
      if ((color.y = color.y - inj) < 0) color.y = 0;
    } else {
      if ((color.y = 1 - inj) < 0) color.y = 0;
    }
  }
  return color;
}

//----------------------------------
#ifdef STRENGTH
#undef STRENGTH
#endif
#define STRENGTH 0
#define XP 1
#define FATIGUE 2
#define INJURED 3
#define WARMED_UP 4
#define RIR 5
list setBP(string json, string bp, integer status_prim, integer body_prim, float rir) {
  integer str = (integer)llJsonGetValue(json, ["strength"]);
  float xp = (float)llJsonGetValue(json, ["xp"]);
  float fat = (float)llJsonGetValue(json, ["fatigue"]);
  if (fat < 0.01) fat = 0.01;
  float injured = (integer)llJsonGetValue(json, ["injured"]);
  integer warmedUp = (integer)llJsonGetValue(json,["warmed-up"]);
  llMessageLinked(LINK_THIS, 0, (string) str, "fw_data:"+bp+"Str");
  llMessageLinked(LINK_THIS, 0, (string) ((integer) (fat * 100)), "fw_data:"+bp+"Pct");
  llMessageLinked(status_prim, UpdateStatus,(string) (xp * 100), NULL_KEY);
  llSetLinkPrimitiveParamsFast(body_prim,
			       [PRIM_COLOR, ALL_SIDES,  getColor(fat,injured), 1.0]);
  return [str, xp, fat, injured, warmedUp, rir];
}

//----------------------------------
list updateBP(list update, string bp, integer status_prim, integer body_prim) {
  integer str = (integer) update[STRENGTH];
  float xp = (float) update[XP];
  float fat = (float) update[FATIGUE];
  float injured = (float) update[INJURED];
  integer warmedUp = (integer) update[WARMED_UP];
  float rir = (float) update[RIR];
  debug(rir);
  debug(injured);
  llMessageLinked(LINK_THIS, 0, (string) str, "fw_data:"+bp+"Str");
  llMessageLinked(LINK_THIS, 0, (string) ((integer) (fat * 100)), "fw_data:"+bp+"Pct");
  llMessageLinked(status_prim, UpdateStatus,(string) (xp * 100), NULL_KEY);
  float y = rir;
  if (fat > rir) y = fat;
  llSetLinkPrimitiveParamsFast(body_prim,
			       [PRIM_COLOR, ALL_SIDES, getColor(y, injured), 1.0]);
  return [str, xp, fat, injured, warmedUp, rir];
}

//----------------------------------
parseSPS(string body) {
  string armsV = llJsonGetValue(body,["arms"]);
  string chestV = llJsonGetValue(body,["chest"]);
  string coreV = llJsonGetValue(body,["core"]);
  string backV = llJsonGetValue(body,["back"]);
  string legsV = llJsonGetValue(body,["legs"]);
  float rir;

  if (arms_values != []) rir = (float) arms_values[RIR]; else rir = 0;
  arms_values = setBP(armsV, "Arms", arms_status, arms_prim, rir);
  if (chest_values != []) rir = (float) chest_values[RIR]; else rir = 0;
  chest_values = setBP(chestV, "Chest", chest_status, chest_prim, rir);
  if (back_values != []) rir = (float) back_values[RIR]; else rir = 0;
  back_values = setBP(backV, "Back", back_status, back_prim, rir);
  if (core_values != []) rir = (float) core_values[RIR]; else rir = 0;
  core_values = setBP(coreV, "Core", core_status, core_prim, rir);
  if (legs_values != []) rir = (float) legs_values[RIR]; else rir = 0;
  legs_values = setBP(legsV, "Legs", legs_status, legs_prim, rir);
  integer total = (integer) arms_values[0] +
    (integer) legs_values[0] +	
    (integer) core_values[0] +
    (integer) back_values[0] +
    (integer) chest_values[0];
  llMessageLinked(LINK_THIS, 0, (string) total, "fw_data: TotalStr");
  string supps = llJsonGetValue(body, ["supplements"]);
  integer len;
  integer i;

  supplements = [];
  messages = [];
  if (supps != JSON_INVALID && supps != JSON_NULL) {
    supplements = llJson2List(supps);
    len = llGetListLength(supplements);
    for (i = 0; i < len; i += 2) {
      messages += [(string) supplements[i]];
    }
  }

  // Messages
  supps = llJsonGetValue(body,["messages"]);
  if (supps != JSON_INVALID && supps != JSON_NULL) {
    list m = llJson2List(supps);
    len = llGetListLength(m);
    for(i = 0; i < len; i += 2) {
      messages += [(string) m[i] + ": " + (string) m[i+1]];
    }
  }

  trainer_dollars = (integer) llJsonGetValue(body, ["points"]);
  messages += ["$T "+(string) trainer_dollars];

  flexibility = (float) llJsonGetValue(body,["flexibility"]);
  string temp = llGetSubString((string)(flexibility*100),0,3);
  messages += ["Flexible: " + temp + "%"];

  aerobic = (float) llJsonGetValue(body,["aerobic"]);
  temp = llGetSubString((string)(aerobic*100),0,3);
  messages += ["Aerobic: " + temp + "%"];
  
  info_index = 0;
  llMessageLinked(LINK_THIS, 0, (string) messages[0], "fw_data: Info");
}

//----------------------------------
parseCardio(float f) {
  integer body_prim;
  float fat;
  float inj;
  if (machine_workout & LEGS_BIT) {
    inj = (float) legs_values[INJURED];
    fat = (float) legs_values[FATIGUE];
    body_prim =legs_prim;
  } else if (machine_workout & ARMS_BIT) {
    inj = (float) arms_values[INJURED];
    fat = (float) arms_values[FATIGUE];
    body_prim = arms_prim;
  }
  if (f > 0) {
    if ((fat = fat - f) < 0.01) fat = 0.01;
  } else {
    if ((fat = fat + f) > 0.99) fat = 0.99;
  }
  vector color = getColor(fat,inj);
  llSetLinkPrimitiveParamsFast(body_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
}

//----------------------------------
initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME, PRIM_DESC]);
    string name = (string) params[0];
    switch (name) {
    case "arms": {
      arms_prim = currentLinkNumber;
      break;
    }
    case "legs": {
      legs_prim = currentLinkNumber;
      break;
    }
    case "core": {
      core_prim = currentLinkNumber;
      break;
    }
    case "back": {
      back_prim = currentLinkNumber;
      break;
    }
    case "chest": {
      chest_prim = currentLinkNumber;
      break;
    }
    case "arms status": {
      arms_status = currentLinkNumber;
      break;
    }
    case "chest status": {
      chest_status = currentLinkNumber;
      break;
    }
    case "legs status": {
      legs_status = currentLinkNumber;
      break;
    }
    case "back status": {
      back_status = currentLinkNumber;
      break;
    }
    case "core status": {
      core_status = currentLinkNumber;
      break;
    }
    default: break;
    }
    currentLinkNumber++;
  }      
}  
//----------------------------------
default {
  on_rez(integer x) {
    initialize();
  }
  
  state_entry() {
    initialize();
    info_index = 0;
    if (llGetAttached()) {
      if (channel == 0) {
	channel = (integer)("0x"+ llGetSubString((string) llGetOwner(), -8, -1));
	handle = llListen(channel, "", NULL_KEY, "");
      }
      llListenControl(handle, TRUE);
      llMessageLinked(LINK_THIS, StartClock, "1800.0", NULL_KEY);
      llMessageLinked(LINK_THIS, startInfoClock, "", NULL_KEY);
      http_handle = llHTTPRequest(SERVER + "sps/get/"+(string) user, [], "");
    }
  }

//----------------------------------
  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Body : PowerUI : 0, 0, 16, 5 : a=left;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ArmsStr : PowerUI : 6, 0, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ChestStr : PowerUI : 6, 1, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : CoreStr : PowerUI : 6, 2, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : BackStr : PowerUI : 6, 3, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : LegsStr : PowerUI : 6, 4, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : TotalStr : PowerUI : 6, 5, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ArmsPct : PowerUI : 14, 0, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ChestPct : PowerUI : 14, 1, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : CorePct : PowerUI : 14, 2, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : BackPct : PowerUI : 14, 3, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : LegsPct : PowerUI : 14, 4, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(LINK_THIS, 0, "Arms\nChest\nCore\nBack\nLegs", "fw_data: Body");
      llMessageLinked(from, 0, "", "fw_addbox : Info : Points : 0, 0, 16, 1 : a=left;c=white;w=none");
      llMessageLinked(LINK_THIS, 0, "$T 0", "fw_data: Info");
      break;
    }
    default: {
      switch (chan) {
      case updateFromServer: {
	debug("updating");
	http_handle = llHTTPRequest(SERVER + "sps/get/"+(string) user, [], "");
	break;
      }
      case infoTick: {
	info_index++;
	if (info_index >= llGetListLength(messages))  info_index = 0;
	llMessageLinked(LINK_THIS, 0, (string) messages[info_index], "fw_data: Info");
	break;
      }
      default: break;
      }
      break;
    }
    }
    channel = 0;
    }

//----------------------------------
  attach(key agent) {
    if (agent == NULL_KEY) {
      if (channel != 0) {
	llListenControl(handle, FALSE);
      }
      machine_channel = 0;
      machine = NULL_KEY;
      llMessageLinked(LINK_THIS, StopClock, "", NULL_KEY);
      llMessageLinked(LINK_THIS, stopInfoClock, "", NULL_KEY);
      return;
    }
    user = agent;
    if (channel == 0) {
      channel = (integer)("0x"+ llGetSubString((string) agent, -8, -1));
      handle = llListen(channel, "", NULL_KEY, "");
    }
    llListenControl(handle, TRUE);
    llMessageLinked(LINK_THIS, StartClock, "1800.0", NULL_KEY);
    llMessageLinked(LINK_THIS, startInfoClock, "", NULL_KEY);
    http_handle = llHTTPRequest(SERVER + "sps/get/"+(string) user, [], "");
  }

//----------------------------------
  changed(integer f) {
    if (user == NULL_KEY) return;
    if (f & (CHANGED_REGION | CHANGED_TELEPORT)) {
      if (machine != NULL_KEY) {
	machine_channel = 0;
	machine = NULL_KEY;
	llMessageLinked(LINK_THIS, StartClock, "30.0", NULL_KEY);
	llMessageLinked(LINK_THIS, startInfoClock, "", NULL_KEY);
	if (recovering)
	  llSetTimerEvent(5);
	else
	  llMessageLinked(LINK_THIS, 0, "Pending...", "fw_data: Info");
      }
    }
  }

//----------------------------------
  http_response(key r, integer status, list meta, string body) {
    if (r == http_handle) {
      parseSPS(body);
    }
  }

//----------------------------------
  listen(integer chan, string name, key xyzzy, string msg) {
    list command = llParseStringKeepNulls(msg, ["|"], []);
    debug(msg);
    switch((string) command[0]) {
    case "rir": {
      integer len = llGetListLength(command);
      integer i;
      
      recovering = FALSE;
      for (i = 1; i < len; ++i) {
	list u = llParseString2List((string) command[i], ["+"], []);
	integer bp = (integer)(string)u[0];
	float rir = (float)(string)u[1];
	float injury = (float)(string)u[2];
	vector color = getColor(rir, injury);
	if (rir > 0) recovering = TRUE;
	
	if (bp == ARMS_BIT) {
	  llSetLinkPrimitiveParamsFast(arms_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
	  arms_values = llListReplaceList(arms_values, [rir], RIR, RIR);
	} else if (bp == CORE_BIT) {
	  llSetLinkPrimitiveParamsFast(core_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
	  core_values = llListReplaceList(core_values, [rir], RIR, RIR);
	} else if (bp == CHEST_BIT) {
	  llSetLinkPrimitiveParamsFast(chest_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
	  chest_values = llListReplaceList(chest_values, [rir], RIR, RIR);
	} else if (bp == BACK_BIT) {
	  llSetLinkPrimitiveParamsFast(back_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
	  back_values = llListReplaceList(back_values, [rir], RIR, RIR);
	} else if (bp == LEGS_BIT) {
	  llSetLinkPrimitiveParamsFast(legs_prim,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
	  legs_values = llListReplaceList(legs_values, [rir], RIR, RIR);
	}
      }
      break;
    }
    case "workout-set": {
      integer len = llGetListLength(command);
      integer i;
      for (i = 1; i < len; ++i) {
	list u = llParseString2List((string) command[i], ["+"], []);
	integer bp = (integer)(string)u[0];
	if (bp == ARMS_BIT) {
	  arms_values = updateBP(llList2List(u,1,-1),"Arms", arms_status, arms_prim);
	} else if (bp == CORE_BIT) {
	  core_values = updateBP(llList2List(u,1,-1),"Core", core_status, core_prim);
	} else if (bp == CHEST_BIT) {
	  chest_values = updateBP(llList2List(u,1,-1),"Chest", chest_status, chest_prim);
	} else if (bp == BACK_BIT) {
	  back_values = updateBP(llList2List(u,1,-1),"Back", back_status, back_prim);
	} else if (bp == LEGS_BIT) {
	  legs_values = updateBP(llList2List(u,1,-1),"Legs", legs_status, legs_prim);
	}
      }
      integer total = (integer) arms_values[0] +
	(integer) legs_values[0] +	
	(integer) core_values[0] +
	(integer) back_values[0] +
	(integer) chest_values[0];
      llMessageLinked(LINK_THIS, 0, (string) total, "fw_data: TotalStr");
      break;
    }
    case "yoga-tick": {
      integer len = llGetListLength(command);
      integer i;
      float dur = (float) (string) command[1];
      for (i = 2; i < len; ++i) {
	list u = llParseString2List((string) command[i], ["+"], []);
	integer bp = (integer)(string)u[0];
	if (bp == ARMS_BIT) {
	  llSetLinkPrimitiveParamsFast(arms_prim,[PRIM_COLOR, ALL_SIDES, getColor((float)(string)u[1], (float)(string)u[2]), 1.0]);
	} else if (bp == CORE_BIT) {
	  llSetLinkPrimitiveParamsFast(core_prim,[PRIM_COLOR, ALL_SIDES, getColor((float)(string)u[1], (float)(string)u[2]), 1.0]);
	} else if (bp == CHEST_BIT) {
	  llSetLinkPrimitiveParamsFast(chest_prim,[PRIM_COLOR, ALL_SIDES, getColor((float)(string)u[1], (float)(string)u[2]), 1.0]);
	} else if (bp == BACK_BIT) {
	  llSetLinkPrimitiveParamsFast(back_prim,[PRIM_COLOR, ALL_SIDES, getColor((float)(string)u[1], (float)(string)u[2]), 1.0]);
	} else if (bp == LEGS_BIT) {
	  llSetLinkPrimitiveParamsFast(legs_prim,[PRIM_COLOR, ALL_SIDES, getColor((float)(string)u[1], (float)(string)u[2]), 1.0]);
	}
      }
      integer min = (integer)(dur / 60);
      string t;
      if (min == 0) {
	t = "00:";
      } if (min <= 9) {
	t = "0" + (string) min + ":";
      } else
	t = (string) min + ":";
      min = (integer) (dur - min * 60);
      if (min == 0) {
	t = t + "00";
      } else if (min <= 9) {
	t = t + "0" + (string) min;
      } else
	t = t + (string) min;
      llMessageLinked(LINK_THIS, 0, t, "fw_data: Info");
      break;
    }

    case "cardio": // in case we need to do something different
    case "workout":  machine_workout = (integer)(string) command[2];
    case "yoga": { // initialize
      llSetTimerEvent(0);
      machine_channel = (integer)(string) command[1];

      machine = xyzzy;
      llMessageLinked(LINK_THIS, StopClock, "", NULL_KEY);
      llMessageLinked(LINK_THIS, stopInfoClock, "", NULL_KEY);

      // HUD will contain body information -- warmed up
      // MACHINE will ack server for STR, FAT, XP and injuries for each body part
      //      and pass that to hud, which updates data.  http data should parse into a strided
      //      list
      llSay(machine_channel, "ack");
      break;
    }
    case "new-workout": { // initialize
      machine_workout = (integer)(string) command[1];
      break;
    }
    case "end": {
      llSetTimerEvent(UPDATE_TIMER);
      // need to start timer
      machine_channel = 0;
      machine = NULL_KEY;
      machine_workout = 0;
      if (recovering) {
	llSetTimerEvent(5);
	llMessageLinked(LINK_THIS, 0, "Resting", "fw_data: Info");
      } else {
	  llMessageLinked(LINK_THIS, 0, "Pending...", "fw_data: Info");
      }
      llMessageLinked(LINK_THIS, StartClock, "30.0", NULL_KEY);
      llMessageLinked(LINK_THIS, startInfoClock, "", NULL_KEY);
      break;
    }
    case "end-cardio": {
      llSetTimerEvent(UPDATE_TIMER);
      // need to start timer
      machine_channel = 0;
      machine = NULL_KEY;
      llMessageLinked(LINK_THIS, StartClock, "60.0", NULL_KEY);
      llMessageLinked(LINK_THIS, startInfoClock, "", NULL_KEY);
      break;
    }
    case "cardio-fatigue": {
      parseCardio((float) (string) command[1]);
      break;
    }
    case "update": {
      parseSPS((string) command[1]);
      break;
    }
    case "reset": {
      llMessageLinked(LINK_THIS, reStartClock, "2.5", NULL_KEY);
      break;
    }
    case "debit": {
      integer cost = (integer)(string)command[1];
      integer supp = (integer)(string)command[2];
      integer vendor = (integer)(string)command[3];
      if (trainer_dollars < cost) {
	llSay(vendor,"0|You have not earned enough trainer dollars.");
	return;
      }
      if (active(supp)) {
	llSay(vendor,"1|Supplement may still be active.  Continue?");
	return;
      }
      llSay(vendor,"1| costs $T "+(string) cost +".  Continue?");
      break;
    }
    case "pay": {
      trainer_dollars += (integer)(string) command[1];
      llMessageLinked(LINK_THIS, 0, "$T "+(string) trainer_dollars, "fw_data: Info");
      break;
    }
    case "info": {
      llMessageLinked(LINK_THIS, 0, (string) command[1], "fw_data: Info");
      break;
    }
    case "version": {
      llSay((integer) command[1], "|" + VERSION_NUM);
      break;
    }
    default: break;
    }
  }

  // RIR recovery
#define timerUpdateRIR(v,p)	    \
  if ((rir = (float) v[RIR]) > 0) { \
    if ((rir = rir - dec) < 0) rir = 0; else recovering = TRUE; \
    vector color = getColor(rir,  (float)v[INJURED]);			\
    llSetLinkPrimitiveParamsFast(p,[PRIM_COLOR, ALL_SIDES, color, 1.0]); \
    v = llListReplaceList(v, [rir], RIR, RIR); \
  }
  
  timer() {
    llSetTimerEvent(0);
    recovering = FALSE;
    float rir;
    float dec = 1.0/12.0;
    timerUpdateRIR(arms_values, arms_prim);
    timerUpdateRIR(core_values, core_prim);
    timerUpdateRIR(chest_values, chest_prim);
    timerUpdateRIR(back_values, back_prim);
    timerUpdateRIR(legs_values, legs_prim);
    if (recovering)
      llSetTimerEvent(5);
    else {
      if (info_index >= llGetListLength(messages))  info_index = 0;
      llMessageLinked(LINK_THIS, 0, (string) messages[info_index], "fw_data: Info");
    }
  }
}
