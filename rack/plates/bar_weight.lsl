#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

list percents;
list rtf;
list spotted;

string current_strength;
float current_percent;
integer current_rtf;

float bonus;

list strengths;
list weights;

integer spotter_link; // used to give rtf spotter bonus
integer initialized;

// ------------------------------
// KEEP IN SYNC WITH REZZER
integer getBar(integer str) {
  // weight of the bar
  if (str > 15000) { str = str -  250; }
  else if (str > 5000) { str = str - 100; }
  else if (str > 500) { str = str - 25; }
  else { str = str - 12; }
  str = ((integer) (str/5.0+0.5))*5;
  // weights
  return str;
}

// --------------------
#define percentStrength(x) ((integer)(strength * x))
#define percentBonusStrength(x) ((integer)((strength * bonus) * x))
#define computeWeight(x) ((string) getBar(percentBonusStrength(x)))

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
}

default {
  on_rez(integer param) {
    initialize();
  }

  state_entry() {
    initialize();
    percents = [0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0];
    rtf = [20, 18, 15, 14, 13, 12, 10, 11, 9,  8, 6, 5, 4, 2, 1]; 
    spotted = [20, 20, 20, 18, 15, 14, 12, 12, 11, 10, 9, 8, 7, 3, 2];
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != initBarAndWeights &&
	chan != selectWeight &&
	chan != chooseWeight &&
	chan != weightsRezzed &&
	chan != resetBarAndWeights) return;
    GET_CONTROL;
    switch (chan) {
    case initBarAndWeights: {
      string s;
      POP(s);
      integer strength = (integer) s;
      bonus = 1;
      POP(s);
      if ((integer) s == 1) {
	debug("tren bonus applied");
	bonus = 1.25;
      }
      integer len = llGetListLength(percents);
      integer i;
      strengths = weights = [];
      for (i = 0; i < len; ++i) {
	strengths = strengths + [ percentStrength((float) percents[i]) ];
	weights = weights + [ computeWeight((float) percents[i]) ];
      }
      llMessageLinked(LINK_THIS, doMenu,
		      sChooseWeight +"|Select workout intesity|Warm up+Hypertrophy+Power",
		      xyzzy);
      break;
    }
    case chooseWeight: {
      integer start = 0;
      integer end = -1;
      string p;
      POP(p);
      switch(p) {
      case "Warm up": {
	end = 5;
	break;
      }
      case "Hypertrophy": {
	start = 3;
	end = 9;
	break;
      }
      case "Power": {
	start = 7;
	break;
      }
      default: break;
      }
      llMessageLinked(LINK_THIS, doMenu,
		      (string) selectWeight +"|Select workout intesity|"+
		      llDumpList2String(llList2List(weights, start, end),"+"),
		      xyzzy);
      break;
    }
    case selectWeight: {
      string m;
      POP(m);
      integer idx = llListFindList(weights, [m]);
      if (idx == -1) return;
      // spotter bonus
      if (llAvatarOnLinkSitTarget(spotter_link) == NULL_KEY)
	current_rtf = (integer) rtf[idx];
      else
      	current_rtf = (integer) spotted[idx];
      debug(current_rtf);
      current_percent = (float) percents[idx] * bonus;
      llMessageLinked(LINK_THIS,
		      rezWeights,
		      current_strength = (string) strengths[idx],
		      xyzzy);
      break;
    }
    case weightsRezzed: {
      PUSH(current_rtf);
      PUSH(current_percent);
      PUSH(current_strength);
      UPDATE_NEXT(barAndWeightsRezzed);
      NEXT_STATE;
      break;
    }
    case resetBarAndWeights: {
      llMessageLinked(LINK_THIS,
		      rezWeights,
		      current_strength,
		      xyzzy);
      break;
    }
    default: break;
    }
  }
}

