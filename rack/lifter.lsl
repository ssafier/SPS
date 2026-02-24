#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

string animation;
string current_strength;
float current_percent;
integer current_rtf;

integer strength;
integer using_trEnergy;

// rezzed weight set
key weight_set;
#define channel (integer)("0x"+llGetSubString((string) weight_set, -4, -1))
integer handle;

key lifter;
key lifter_prim;
integer lifter_link;

// resting
#define restingInterval 5.0
float rest_factor;
float rest_time;

integer initialized = FALSE;
// ------------------------------
integer fromNode(string node, string data) {
  list l = llParseString2List(data,["|"],[]);
  integer n = 6;
  if ((string) l[0] == "STRING") n = 3;
  return (llGetListLength(l) >= n) && ((string) l[n-1] == node);
}

// ------------------------------
reset() {
  if (weight_set != NULL_KEY) llShout(channel, "die");
  weight_set = NULL_KEY;
  if (lifter != NULL_KEY) llMessageLinked(LINK_THIS, savePositions, "|", lifter);
  llMessageLinked(LINK_SET, ClearLifter, "", NULL_KEY);
  llMessageLinked(LINK_THIS, setupRack, "|[RESET]", NULL_KEY);
  llMessageLinked(LINK_THIS, WorkoutReset, "", NULL_KEY);
  llMessageLinked(LINK_THIS, stopLifting, "", NULL_KEY);
  llMessageLinked(LINK_THIS, resetTrainer, "", NULL_KEY);
  llMessageLinked(LINK_SET, resetAnimationState, "", NULL_KEY);
}

// ------------------------------
initialize() {
  if (initialized) return;
  initialized = TRUE;
  lifter_prim = llGetLinkKey(LINK_THIS);
  lifter_link = LINK_THIS;
}

// ------------------------------

barAndWeightsRezzedImpl(string weight) {
  debug("bar "+msg);
  llMessageLinked(LINK_THIS, 0, weight, "fw_data: Weight");
  if (handle) llListenRemove(handle);
  handle = llListen(channel,"bar",NULL_KEY,"");
  llListenControl(handle, FALSE);
}

// ------------------------------

displayMenu(string s) {
  switch(s) {
  case "Workout": {
    llListenControl(handle, TRUE);
    llSay(channel,"attach|"+(string) lifter + "|" + animation); // control passed through listen event
    break;
  }
  case "New Exercise": {
    if (weight_set != NULL_KEY) llShout(channel, "die");
    weight_set = NULL_KEY;
    llMessageLinked(LINK_THIS,getPosForEquipment,
		    sSetupRack + "+" +
		    sInitializeLifter + "+" +
		    sConfigureEquipment + "+" +
		    sNewWorkout + "+" +
		    sReStand + "|<root node>",
		    lifter);
    break;
  }
  case "Re-Weight": {
    if (weight_set != NULL_KEY) llShout(channel, "die");
    weight_set = NULL_KEY;
    llMessageLinked(LINK_THIS, initBarAndWeights, "|" + (string) strength, lifter);
    break;
  }
  case "Get a spot": {
    llMessageLinked(LINK_THIS, getTrainer, "", lifter);
    break;
  }
  case "[Stand]": {
    reset();
    llSleep(0.25);
    llUnSit(lifter);
    break;
  }
  default: break;
  }
}

// ---------------------------------------

restand(string s) {
  if (weight_set != NULL_KEY) llShout(channel, "die");
  weight_set = NULL_KEY;
  strength = (integer) s;
  llMessageLinked(LINK_THIS, initBarAndWeights, "|" + (string) strength, lifter);
  llMessageLinked(LINK_THIS, getLeaf, (string) returnPosLeaf + "+" + sInitiateStand +"|" + animation+"-STAND", lifter);
}

// ---------------------------------------

default {
  on_rez(integer param) {
    initialize();
  }

  state_entry() {
    initialize();
    weight_set = lifter = NULL_KEY;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == ResetWorkout) {
      animation = "";
      return;
    }
    if (chan != initiateStand &&
	chan != initializeLifter &&
	chan != checkWorkoutFail &&
	chan != barAndWeightsRezzed &&
	chan != WorkoutInitialized) return;
    GET_CONTROL;
    string popper;
    switch (chan) {
    case initializeLifter: {
      PEEK(animation);
      break;
    }
    case barAndWeightsRezzed: { // bar was rezzing, so kill it
      POP(popper);
      POP(popper);  current_percent = (float) popper;
      POP(popper); current_rtf = (integer) popper;
      string weight;  POP(weight); // weight;
      POP(popper); weight_set = (key) popper;
      llMessageLinked(LINK_THIS, 0, weight+" KG", "fw_data: Weight");
      llSay(channel, "die");
      weight_set = NULL_KEY;
      break;
    }
    case WorkoutInitialized: {
      POP(popper);
      debug("workout initialized "+popper);
      strength = (integer) popper;
      POP(popper);
      using_trEnergy = (integer) popper;
      state workout;
      break;
    }
    case checkWorkoutFail: {
    if (weight_set != NULL_KEY) llShout(channel, "die");
    weight_set = NULL_KEY;
    llMessageLinked(LINK_THIS,getPosForEquipment,
		    sSetupRack + "+" +
		    sInitializeLifter + "+" +
		    sConfigureEquipment + "+" +
		    sNewWorkout + "+" +
		    sWorkoutInitialized + "|<root node>",
		    lifter);
      break;
    }
    case initiateStand: {
      lifter = xyzzy;
      lifter_link = -1;
      integer objectPrimCount = llGetObjectPrimCount(llGetKey());
      integer currentLinkNumber = 0;
      while(currentLinkNumber <= objectPrimCount && lifter_link == -1 ) {
	++currentLinkNumber;
	if (llGetLinkKey(currentLinkNumber) == lifter) lifter_link = currentLinkNumber;
      }
      if (lifter_link == -1) llOwnerSay("Can't find lifter");
      llMessageLinked(LINK_THIS, animateWithSpotter,
		      "|" + animation+"-STAND" + "|" + (string)(afStopAll | afCache),
		      lifter);
      //HERE: call workout, workout returns and we go to standing
      debug("init workout");
      llMessageLinked(LINK_THIS, InitializeWorkout, sWorkoutInitialized +"|" + animation, 
		      lifter);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
}

// initial state when workout selected
state workout {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    llMessageLinked(LINK_THIS,
		    initBarAndWeights, "|" + (string) strength + "|" + (string) using_trEnergy,
		    lifter);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != barAndWeightsRezzed &&
	chan != returnIntensityLeaf &&
	chan != returnLeaf &&
	chan != initializeLifter &&
	chan != ReStand) return;
    GET_CONTROL;
    string popper;
    switch(chan) {
    case barAndWeightsRezzed: {
      POP(current_strength);
      POP(popper);  current_percent = (float) popper;
      POP(popper); current_rtf = (integer) popper;
      string weight;  POP(weight); // weight;
      POP(popper); weight_set = (key) popper;
      barAndWeightsRezzedImpl(weight);
      // get the weight to workout with
      llMessageLinked(LINK_THIS,
		      checkSpotterMenu,
		      (string) getLeaf + "+" + (string) returnIntensityLeaf + "|", lifter);
      break;
    }
    case initializeLifter: {
      PEEK(animation);
      break;
    }
    case returnIntensityLeaf: {
      string s;
      POP(s);
      if (s != "STRING") return;
      POP(s);
      displayMenu(s);
      break;
    }
    case ReStand: {
      POP(popper);
      restand(popper);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }

  state_exit() {
    llListenRemove(handle);
    handle = 0;
  }

  changed(integer f) {
    if (f & CHANGED_LINK) {
      // lsl BUG, not guaranteed to work
      if (llAvatarOnSitTarget() == NULL_KEY ||
	  llGetLinkKey(lifter_link) == NULL_KEY ||
	  llAvatarOnSitTarget() != llGetLinkKey(lifter_link)) {
	reset();
	state default;
      }
    }
  }

  touch_start(integer x) {
    if (llDetectedKey(0) != lifter) return;
    llMessageLinked(LINK_THIS, checkSpotterMenu,
		    (string) getLeaf + "+" + (string) returnIntensityLeaf + "|", lifter);
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    llMessageLinked(LINK_THIS, getPosFromConfig, "|"+animation, lifter);
    state lifting;
  }
}


// attach bar and start lifting
state lifting {
  state_entry() {
    integer bar_channel = channel;
    llMessageLinked(LINK_THIS, Lifting,
		    "|" + animation + "|" + (string) current_rtf + "|" + (string) current_percent + "|" + (string) lifter_link + "|" + (string) bar_channel,
		    lifter);
  }
  changed(integer f) {
    if (f & CHANGED_LINK) {
      if (llAvatarOnSitTarget() == NULL_KEY ||
	  llGetLinkKey(lifter_link) == NULL_KEY ||
	  llAvatarOnSitTarget() != llGetLinkKey(lifter_link)) {
	reset();
	state default;
      }
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != LiftingDone && chan != barAndWeightsRezzed) return;
    GET_CONTROL;
    string popper;
    switch (chan) {
    case LiftingDone: {
      POP(popper);
      rest_factor = 90;
      if ((integer) popper == 1) rest_factor = 60;
      llSay(channel, "detach");
      llMessageLinked(LINK_THIS, resetBarAndWeights, "", lifter);
      break;
    }
    case barAndWeightsRezzed: {
      POP(current_strength);
      POP(popper);  current_percent = (float) popper;
      POP(popper); current_rtf = (integer) popper;
      string weight;  POP(weight); // weight;
      POP(popper); weight_set = (key) popper;
      barAndWeightsRezzedImpl(weight);
      llMessageLinked(LINK_THIS, getPosFromConfig, "|" + animation+"-REST", lifter);
      state resting;
    }
    default: break;
    }
  }
}

// similar to workout, but updates resting and uses controls for menu and  workout
state resting {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    rest_time = 0;
    llRegionSayTo(lifter,0,"Touch mat for menu.  PAGE DOWN to start working out, PAGE UP to stand.");
    llMessageLinked(LINK_THIS, startResting, "|", lifter);
    llMessageLinked(LINK_THIS, animateWithSpotter,
		    "|" + animation+"-REST" + "|" + (string) (afCache | afReplace),
		    lifter);
    if (handle) llListenRemove(handle);
    handle = llListen(channel,"bar",NULL_KEY,"");
    llListenControl(handle, FALSE);
    llSetTimerEvent(5);
    llRequestExperiencePermissions(lifter, "");
  }

  experience_permissions(key avi) {
    llTakeControls(CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
    llMessageLinked(LINK_THIS, checkWorkout, "|", lifter);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != barAndWeightsRezzed &&
	chan != returnLeaf &&
	chan != ReStand &&
	chan != checkWorkoutFail &&
	chan != initializeLifter &&
	chan != Rested) return;
    GET_CONTROL;
    string popper;
    switch(chan) {
    case Rested: {
      llSetTimerEvent(0);
      break;
    }
    case initializeLifter: {
      PEEK(animation);
      break;
    }
    case barAndWeightsRezzed: {
      debug("bar "+msg);
      POP(current_strength);
      POP(popper);  current_percent = (float) popper;
      POP(popper); current_rtf = (integer) popper;
      string weight;  POP(weight); // weight;
      POP(popper); weight_set = (key) popper;
      barAndWeightsRezzedImpl(weight);
      break;
    }
    case returnLeaf: {
      // remove?      if (fromNode("Seated",data) == FALSE) return;
      debug("return leaf 2 "+data);
      string s;
      POP(s);
      if (s != "STRING") return;
      POP(s);
      displayMenu(s);
      break;
    }
    case checkWorkoutFail: {
      if (weight_set != NULL_KEY) llShout(channel, "die");
      weight_set = NULL_KEY;
      llMessageLinked(LINK_THIS,getPosForEquipment,
		      sSetupRack + "+" +
		      sInitializeLifter + "+" +
		      sConfigureEquipment + "+" +
		      sNewWorkout + "+" +
		      sReStand + "|<root node>",
		      lifter);
      break;
    }
    case ReStand: {
      POP(popper);
      restand(popper);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }

  state_exit() {
    llReleaseControls();
    llListenRemove(handle);
    handle = 0;
  }

  changed(integer f) {
    if (f & CHANGED_LINK) {
      if (llAvatarOnSitTarget() == NULL_KEY ||
	  llGetLinkKey(lifter_link) == NULL_KEY ||
	  llAvatarOnSitTarget() != llGetLinkKey(lifter_link)) {
	reset();
	state default;
      }
    }
  }

  touch_start(integer x) {
    if (llDetectedKey(0) != lifter) return;
    llMessageLinked(LINK_THIS, checkSpotterMenu,
		    (string) getLeaf + "+" + (string) returnLeaf + "|", lifter);
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    llSetTimerEvent(0);
    debug("going to lifting");
    llMessageLinked(LINK_THIS, getPosFromConfig, "|"+animation, lifter);
    state lifting;
  }

#include "include/takecontrol.h"
  
  control(key id, integer held, integer change) {
    if (start_up) {
      llMessageLinked(LINK_THIS, checkSpotterMenu,
		      (string) getLeaf + "+" + (string) returnLeaf + "|", lifter);
      return;
    }
    if (start_down) {
      llListenControl(handle, TRUE);
      llSay(channel,"attach|"+(string) lifter + "|" + animation);
    }
  }
  
  timer() {
    rest_time += restingInterval;
    llMessageLinked(LINK_THIS, restInterval, "|" + (string) ((integer) rest_time) + "|" +
		    (string)(1.0 / (rest_factor / restingInterval)),
		    lifter);
   }
}

