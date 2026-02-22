#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#define NOTECARD_NAME ".workouts"
#define FatigueRIRFactor 4.0

key handle_key;

// name body primary secondary
list workouts;

// strided list of supplement name and id
list supplements;

list arms_values;
list legs_values;
list chest_values;
list core_values;
list back_values;

integer current_workout;
integer current_primary;
integer current_secondary;
integer recovery_workout;

float cardioF;
float flexibility;

key lifter;
integer lifter_channel;
integer channel;
integer handle;
integer spotter_link;

integer initialized;

integer set_warmed_up;

float total_xp;
float total_fatigue;
integer primary_workout_targets;

GLOBAL_DATA;

#define SayToHud(x) if (lifter_channel != 0) llSay(lifter_channel, (string)(x))

//----------------------------------
// is a supplement active
integer active(integer s) {
  integer l = llGetListLength(supplements);
  integer i;
  for(i = 1; i < l; i += 2) {
    if ((integer)(string)supplements[i] == s) return TRUE;
  }
  return FALSE;
}

//----------------------------------
// XP
#define BaseXP 0.05
#define BaseExponent 2.0
float xpGain(float pct, float fat, float rf) {
  debug("gain "+(string) pct + " " + (string) fat + " " + (string) rf);
  debug((string)(BaseXP *  llPow(pct, BaseExponent) * (1.0/llSqrt(fat)) * rf));
  return (BaseXP * llPow(pct, BaseExponent) * (1.0/llSqrt(fat)) * rf) * (1 + cardioF / 2.0);
}

//----------------------------------
// Fat 
#define LEGS_MULT 5.0
#define BACK_MULT 4.0
#define CHEST_MULT 3.0
#define CORE_MULT 1.5
#define ARMS_MULT 1.5
#define FatConst 100.0
float fatGain(float pct, integer reps, float bp) {
  debug("fat "+(string) pct + " " + (string) reps + " " + (string) bp);
  debug((string)(((pct*pct*pct) * reps * bp)/FatConst));
  return (((pct*pct*pct) * reps * bp)/FatConst) * (1 - cardioF / 3.0);
}

//----------------------------------
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

list setBP(string json) {
  integer str = (integer)llJsonGetValue(json, ["strength"]);
  float xp = (float)llJsonGetValue(json, ["xp"]);
  float fat = (float)llJsonGetValue(json, ["fatigue"]);
  float injured = (float)llJsonGetValue(json, ["injured"]);
  integer warmedUp = (integer)llJsonGetValue(json,["warmed-up"]);
  if (fat < 0.01) fat = 0.01;
  return [str, xp, fat, injured, warmedUp, 0.0, FALSE];
}

//----------------------------------
list getWorkout(string name) {
  // debug("workout "+name);
  integer len = llGetListLength(workouts);
  integer i;
  for (i = 0; i < len; i += 4) {
    // debug((string) workouts[i]);
    if ((string) workouts[i] == name)
      return [(integer) workouts[i+1], (integer) workouts[i+2], (integer) workouts[i+3]];
  }
  return [0, 0, 0];
}

//----------------------------------
string values2Json(list v) {
  if ((integer) v[MODIFIED])
    return "{ \"xp\": "+(string)(float)v[XP]+", "+
      "\"strength\":"+(string)(integer)v[STRENGTH]+", "+
      "\"fatigue\":"+(string)(float)v[FATIGUE]+", "+
      "\"injured\":"+(string)(float)v[INJURED]+", "+
      "\"warmed-up\":"+(string)(integer)v[WARMED_UP]+"}";
  else
    return "";
}

//----------------------------------
string export2Json(key lifter) {
  string output = "{\"lifter\": \""+(string) lifter + "\"";
  string temp = values2Json(arms_values);
  if (temp != "") output = output +  ", \"arms\": "+ temp;
  temp = values2Json(chest_values);
  if (temp != "") output = output + ", \"chest\": "+ temp;
  temp = values2Json(core_values);
  if (temp != "") output = output + ", \"core\": "+ temp;
  temp = values2Json(back_values);
  if (temp != "") output = output + ", \"back\": "+ temp;
  temp = values2Json(legs_values);
  if (temp != "") output = output + ", \"legs\": "+ temp;
  return output + "}";
}

//----------------------------------
string strength() {
  integer str = 0;
  // debug(current_workout);
  if (current_workout & ARMS_BIT) str += (integer) arms_values[STRENGTH];
  if (current_workout & CORE_BIT) str += (integer) core_values[STRENGTH];
  if (current_workout & CHEST_BIT) str += (integer) chest_values[STRENGTH];
  if (current_workout & BACK_BIT) str += (integer) back_values[STRENGTH];
  if (current_workout & LEGS_BIT) str += (integer) legs_values[STRENGTH];
  // debug(str);
  return (string) str;
}

//----------------------------------
list maxRIR(integer b, list v, float inc, float intensity, integer reps) {
  if (current_workout & b) {
    float next;
    float temp = (float) v[RIR]; 
    float ink = inc; 
    if (current_secondary & b) {
      ink = inc / 2.0;
    } else if ((current_primary & b) == 0) {
      ink = inc / 3.0;
    }					       
    if ((next = temp + ink) > 1.0) next = 1.0; 
    temp = temp + (float) v[FATIGUE]/FatigueRIRFactor; 

    float integrity = 1; 
    if (current_primary & b) {
      float risk = (float) v[INJURED] * ((1-flexibility) / 2.0);
      if (active(trEnergy)) risk *= 1.2;
      if (risk > llFrand(1.0)) {
	float damage = reps * llPow(intensity, 3) * 0.5;
	if (active(trEnergy)) damage *= 1.5;
	integrity -= damage / 100.0;
	if (integrity < 0.01) integrity = 0.01;
      }
      if (active(trEnergy) && (integrity > 0.9)) integrity = 0.9;	
    }
    return [temp, b, next, 1.0-integrity];	
  }
  return [];
}

float max_rir_and_update(float inc, float intensity, integer reps) {
  float rir = 0;
  // debug(current_workout);
  list hud = [];
  list val = maxRIR(ARMS_BIT,  arms_values, inc, intensity, reps);
  if (val != []) {
    rir = (float) val[0];
    arms_values = llListReplaceList(llListReplaceList(arms_values, [(float) val[2]], RIR, RIR),
				    [(float) val[3]], INJURED, INJURED);
    hud = [llDumpList2String(llList2List(val,1,-1),"+")];
  }
  val = maxRIR(CORE_BIT, core_values, inc, intensity, reps);
  if (val != []) {
    if ((float) val[0] > rir) rir = (float) val[0];
    core_values = llListReplaceList(llListReplaceList(core_values, [(float) val[2]], RIR, RIR),
				    [(float) val[3]], INJURED, INJURED);	
    hud += llDumpList2String(llList2List(val,1,-1),"+");
  }
  val = maxRIR(CHEST_BIT, chest_values, inc, intensity, reps);
  if (val != []) {
    if ((float) val[0] > rir) rir = (float) val[0];
    chest_values = llListReplaceList(llListReplaceList(chest_values, [(float) val[2]], RIR, RIR),
				     [(float) val[3]], INJURED, INJURED);
    hud += llDumpList2String(llList2List(val,1,-1),"+");
  }
  val = maxRIR(BACK_BIT, back_values, inc, intensity, reps);
  if (val != []) {
    if ((float) val[0] > rir) rir = (float) val[0];
    back_values = llListReplaceList(llListReplaceList(back_values, [(float) val[2]], RIR, RIR),
				    [(float) val[3]], INJURED, INJURED);
    hud += llDumpList2String(llList2List(val,1,-1),"+");
  }
  val = maxRIR(LEGS_BIT, legs_values, inc, intensity, reps);
  if (val != []) {
    if ((float) val[0] > rir) rir = (float) val[0];
    legs_values = llListReplaceList(llListReplaceList(legs_values, [(float) val[2]], RIR, RIR),
				    [(float) val[3]], INJURED, INJURED);
    hud += llDumpList2String(llList2List(val,1,-1),"+");
  }
  if (hud != []) SayToHud("rir|"+llDumpList2String(hud,"|"));
  // debug(rir);
  return rir;
}

//----------------------------------
#define restRIR(b,v)   if (recovery_workout & b) {\
    temp = (float) v[RIR];\
    if ((next = temp - inc) <= ((float) v[FATIGUE] / FatigueRIRFactor)) {\
      next = (float) v[FATIGUE] / FatigueRIRFactor;\
    } else { rested = FALSE;  }\
    temp = temp + (float) v[FATIGUE];\
    v = llListReplaceList(v, [next], RIR, RIR);\
    hud+= [(string) b + "+" + (string) next];  }

integer rest_rir_and_update(float inc) {
  float rir = 0;
  float temp;
  float next;
  list hud;
  integer rested = TRUE;
  restRIR(ARMS_BIT,  arms_values);
  restRIR(CORE_BIT, core_values);
  restRIR(CHEST_BIT, chest_values);
  restRIR(BACK_BIT, back_values);
  restRIR(LEGS_BIT, legs_values);
  if (hud != []) SayToHud("rir|"+llDumpList2String(hud,"|"));
  // debug(rested);
  return rested;
}

//----------------------------------
#define wup(b,v)   if (current_workout & b) { if (((integer) v[WARMED_UP] == FALSE) && ((float) v[RIR] >= 1.0)) return TRUE;  }

integer warmed_up() {
  integer val = 0;
  wup(ARMS_BIT, arms_values);
  wup(CORE_BIT, core_values);
  wup(CHEST_BIT, chest_values);
  wup(BACK_BIT, back_values);
  wup(LEGS_BIT, legs_values);
  return TRUE;
}

//----------------------------------
list compute(list values,  integer reps,   float intensity, integer level, 
	     float mult,  integer primary,  integer secondary) {
    integer strength= (integer) values[STRENGTH];
    float xp = (float) values[XP];
    float fatigue = (float) values[FATIGUE];
    float rir = (float) values[RIR];
    float integrity = 1.0 - (float) values[INJURED];
    float rf = 1.0;

    integer priority = 1;
    if (secondary) {
      priority = 2;
    } else if (primary == 0) {
      priority = 3;
    }

    // injury here
    float risk = (float) values[INJURED] * ((1-flexibility) / 2.0);
    if (active(trEnergy)) risk *= 1.2;
    
    if (risk > llFrand(1.0)) {
      float damage = reps * llPow(intensity, 3) * 0.5;
      if (active(trEnergy)) damage *= 1.5;
      integrity -= damage / 100.0;
      if (integrity < 0.01) integrity = 0.01;
      //llOwnerSay("Injured "+(string)integrity);
    }
    
    if (reps >= 6 && reps <= 10) {
      rf = 1.2;
    } else if (reps >= 10) {
      rf = 1.4;
    }
    // decrease xp as you get intured
    float temp = (xpGain(intensity, fatigue, rf) / (float) priority) * llPow(integrity,2);
    xp += temp;
    total_xp += temp;
    while (xp >= 1.0) {
      strength++;
      xp = xp - 1.0;
    }
    temp = fatGain(intensity, reps, mult) / (float) priority;
    fatigue += temp;
    total_fatigue += temp;
    if (fatigue > 1.0) fatigue = 1.0;
    return [strength, xp, fatigue, 1 - integrity, set_warmed_up, rir, TRUE];
}

#define hud_string(b, v) (string) b + "+" + llDumpList2String(llList2List(v, 0, -2), "+")
#define pub(b, m, v)   if (current_workout & b) {v = compute(v, reps, intensity, level, m, current_primary & b,  current_secondary & b);  hud += [hud_string(b, v)];  }

publish(integer reps, float intensity, integer level) {
  integer val = 0;
  list hud = [];
  pub(ARMS_BIT, ARMS_MULT, arms_values);
  pub(CORE_BIT, CORE_MULT, core_values);
  pub(CHEST_BIT, CHEST_MULT, chest_values);
  pub(BACK_BIT, BACK_MULT, back_values);
  pub(LEGS_BIT, LEGS_MULT, legs_values);
  // debug("workout-set|" + llDumpList2String(hud,"|"));
  if (hud != []) SayToHud("workout-set|" + llDumpList2String(hud,"|"));
}

//----------------------------------

#define testInjured(b, v) ((current_primary & b) && ((float) v[INJURED] > 0.6))
#define testFatigue(b,v) ((current_workout & b) && ((float) v[FATIGUE] > 0.95))

integer testForInjury() {
  if (testInjured(ARMS_BIT, arms_values) ||
      testInjured(CORE_BIT, core_values) ||
      testInjured(CHEST_BIT, chest_values) ||
      testInjured(BACK_BIT, back_values) |
      testInjured(LEGS_BIT, legs_values)) return 1;
  return 0;
}

integer testWorkout() {
  if (testInjured(ARMS_BIT, arms_values) ||
      testInjured(CORE_BIT, core_values) ||
      testInjured(CHEST_BIT, chest_values) ||
      testInjured(BACK_BIT, back_values) |
      testInjured(LEGS_BIT, legs_values)) return 1;
  if (testFatigue(ARMS_BIT, arms_values) ||
      testFatigue(CORE_BIT, core_values) ||
      testFatigue(CHEST_BIT, chest_values) ||
      testFatigue(BACK_BIT, back_values) |
      testFatigue(LEGS_BIT, legs_values)) return 2;
  return 0;
}

//----------------------------------

initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  spotter_link = -1;
  debug(objectPrimCount);
  while(currentLinkNumber <= objectPrimCount) {
    debug(currentLinkNumber);
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME, PRIM_DESC]);
    debug((string) params[0] + " " + (string) params[1]);
    switch((string) params[0]) {
    case "spotter prim": {
      spotter_link = currentLinkNumber;
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
  total_fatigue = total_xp = 0.0;
  primary_workout_targets = 0;
  cardioF = 0.1;
}

#define hasSpotter() (llAvatarOnLinkSitTarget(spotter_link) != NULL_KEY)

default {
  on_rez(integer x) {
    initialize();
  }

  state_entry() {
    initialize();
    workouts = [];
    llSay(0, "Reading workouts file...");
    handle_key = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }
  
//----------------------------------
#define setBPworkout(b) \
		  workout += b;  switch (priority) { case 1: {primary += b; break; } case 2: { secondary += b; break; } default: break; }

  dataserver(key request, string data)  {
    if (request == handle_key) {
      handle_key = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  debug("Notecard line reading failed");
	} else if (line != EOF) {
	  if (line != "") {
	    list l = llParseString2List(line, ["|"], []);
	    switch(llToLower((string) l[0])) {
	    case "exercise": {
	      integer workout = 0;
	      integer primary = 0;
	      integer secondary = 0;
	      list w = llParseString2List((string) l[2], ["+"], []);
	      integer len = llGetListLength(w);
	      integer i;
	      for (i = 0; i < len; ++i) {
		string bp = (string) w[i];
		integer priority = 1;
		integer index = llSubStringIndex(bp, ":");
		if (index != -1) {
		  priority = (integer) llGetSubString(bp, index + 1, -1);
		  bp = llGetSubString(bp, 0, index -1);
		}
		switch(llToLower(bp)) {
		case "arms": {
		  setBPworkout(ARMS_BIT);
		  break;
		}
		case "chest": {
		  setBPworkout(CHEST_BIT);
		  break;
		}
		case "core": {
		  setBPworkout(CORE_BIT);
		  break;
		}
		case "back": {
		  setBPworkout(BACK_BIT);
		  break;
		}
		case "legs": {
		  setBPworkout(LEGS_BIT);
		  break;
		}
		default: break;
		}
	      }
	      workouts = [(string) l[1], workout, primary, secondary] + workouts;
	      break;
	    }
	    default: break;
	    }
	  }
	} else {
	  llSay(0,"Workouts loaded.");
	  channel = (integer)("0x"+ llGetSubString((string) llGetKey(), -8, -1));
	  handle = llListen(channel, "", NULL_KEY, "");
	  llListenControl(handle, FALSE);	}
      }
    }
  }

//----------------------------------
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != InitializeWorkout &&
	chan != NewWorkout &&
	chan != WorkoutReset &&
	chan != getRep &&
	chan != checkWorkout &&
	chan != publishSet &&
	chan != startResting &&
	chan != restInterval) return;
    GET_CONTROL_GLOBAL;
    string a;
    switch (chan) {
    case getRep: {
      POP(a);
      integer rep = (integer) a;
      POP(a);
      integer rtf = (integer) a;
      POP(a);
      float intensity = (float) a;
      float sfactor = 1.0;
      integer sb = 1;
      
      if (hasSpotter()) {
	sfactor = 2.0;
	sb = 3;
      }
      if (rep == 1) { set_warmed_up = warmed_up(); }
      float wf = 1.0;
      // rtf comes from the bar and in influenced by creatine and spotter
      if (active(creatine)) wf = 0.75;
      float new_rir = (float) wf / (rtf + sb); 
      float maxRIR = max_rir_and_update(new_rir, intensity, rep);
      float time;
      integer level;
      integer terminal = FALSE;
      SayToHud("info|Rep " + (string) (rep-1)); // because we cache
      if (testForInjury()) { level = 5; time = 4.5; terminal = TRUE; } else
      if ((maxRIR + new_rir) > 0.95 || (intensity > 0.55 && rep >= rtf)) {
	level = 4;	time = 4.5; terminal = TRUE;
      } else if (maxRIR > 0.75) {
	level = 3;	time = 4;
      } else
        if (maxRIR > 0.5) { level = 2; time = 4; } else { level = 1; time = 3;  }
      PUSH(terminal); PUSH(time); PUSH(level);
      NEXT_STATE;
      break;
    }
    case publishSet: {
      // debug("publish "+msg);
      POP(a);
      integer rep = (integer) a;
      POP(a);
      integer rtf = (integer) a;
      POP(a);
      float intensity = (float) a;
      POP(a);
      integer level = (integer) a;
      publish(rep, intensity, level);
      llMessageLinked(LINK_THIS, publishSetForSpotter, "", NULL_KEY);
      PUSH(active(protein_shake));
      NEXT_STATE;
      break;
    }
    case restInterval: {
      string interval;
      POP(interval);
      string inc;
      POP(inc);
      integer rested = rest_rir_and_update(((float) inc) * (1 + cardioF));  // cardio bonus
      if (rested) {
	SayToHud("info|Rested");
	recovery_workout = 0;
	llMessageLinked(LINK_THIS, Rested, "|"+interval, lifter);
      } else {
	SayToHud("info|Resting " + (string) interval + " sec");
      }
      break;
    }
    case startResting: {
      SayToHud("info|Resting 0 sec");
      recovery_workout = recovery_workout | current_workout;
      break;
    }
    case NewWorkout: {
      POP(a);
      list ws = getWorkout(a);
      current_workout = (integer) ws[0];
      current_primary = (integer) ws[1];
      current_secondary = (integer) ws[2];
      primary_workout_targets = primary_workout_targets | current_primary;
      debug((string) primary_workout_targets);
    }
    case checkWorkout: {
      switch (testWorkout()) {
      case 0: {
	if (chan == NewWorkout) {
	  SayToHud("new-workout|"+(string) current_workout);
	  set_warmed_up = FALSE;
	  PUSH(strength());
	}
	NEXT_STATE;
	break;
      }
      case 1: {
	llRegionSayTo(lifter, 0, "You are injured and cannot do this workout.  Please choose a different exercise.");
	llMessageLinked(LINK_THIS, checkWorkoutFail, "|injured", lifter);
	break;
      }
      case 2: {
	llRegionSayTo(lifter, 0, "You are too tired for this workout.  Please choose a different exercise.");
	llMessageLinked(LINK_THIS, checkWorkoutFail, "|fatigue", lifter);
	break;
      }
      default: break;
      }
      break;
    }
    case InitializeWorkout: {
      POP(a);
      list ws = getWorkout(a);
      current_workout = (integer) ws[0];
      primary_workout_targets = current_primary = (integer) ws[1];
      debug((string) primary_workout_targets);
      current_secondary = (integer) ws[2];
      set_warmed_up = FALSE;
      total_fatigue = total_xp = 0;
      llMessageLinked(LINK_THIS, StartLog, "", NULL_KEY);
      lifter = xyzzy;
      debug("lifter is "+(string) lifter);
      lifter_channel = (integer)("0x"+ llGetSubString((string) lifter, -8, -1));
      SayToHud("workout|"+(string) channel + "|" + (string) current_workout);
      cardioF = 0.1;
      handle_key = llHTTPRequest(SERVER + "sps/get/"+(string) lifter, [], "");
      break;
    }
    case WorkoutReset: {
      if (lifter_channel != 0) SayToHud("end");
      set_warmed_up = FALSE;
      lifter_channel = 0;
      if (lifter != NULL_KEY) {
	debug("lifter is still "+(string) lifter);
	debug((string) primary_workout_targets);
	llMessageLinked(LINK_THIS, SaveLog, (string) saveSpotter +
			"|2|" + (string) total_xp + "|" + (string) total_fatigue + "|" +
			(string) primary_workout_targets + "|" +
			export2Json(lifter), lifter);
      }
      total_xp = 0;
      total_fatigue = 0;
      primary_workout_targets = 0;
      lifter = NULL_KEY;      
      llListenControl(handle, FALSE);
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }	
  }

//----------------------------------
  http_response(key r, integer status, list meta, string body) {
    if (r == handle_key) {
      if (status != 200) {
	llSay(0, "Server error "+(string) status+".  Please try again.");
	llUnSit(lifter);
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
      arms_values = setBP(armsV);
      chest_values = setBP(chestV);
      back_values = setBP(backV);
      core_values = setBP(coreV);
      legs_values = setBP(legsV);
      cardioF = (float) aerobic;
      flexibility = (float) flex;
      string supps = llJsonGetValue(body, ["supplements"]);
      supplements = [];
      if (supps != JSON_INVALID && supps != JSON_NULL) {
	supplements = llJson2List(supps);
      }

      switch (testWorkout()) {
      case 0: {
	key xyzzy = lifter;
	PUSH(active(trEnergy));
	PUSH(strength());
	NEXT_STATE;
	break;
      }
      case 1: {
	llRegionSayTo(lifter, 0, "You are injured and cannot do this workout.  Please choose a different exercise.");
	llMessageLinked(LINK_THIS, checkWorkoutFail, "|injured", lifter);
	break;
      }
      case 2: {
	llRegionSayTo(lifter, 0, "You are too tired for this workout.  Please choose a different exercise.");
	llMessageLinked(LINK_THIS, checkWorkoutFail, "|fatigue", lifter);
	break;
      }
      default: break;
      }
    }
  }
  
  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) {
      state default;
    }
  }
}
