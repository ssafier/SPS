#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer has_trainers;
integer inUse;
key client;

default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    llSetText("No trainers.", <0,1,1>,1);
  }
  touch_start(integer x) {
    integer link = llDetectedLinkNumber(0);
    if (link != llGetLinkNumber()) return;
    if (!has_trainers) {
      llSay(0, "There are no trainers available to give a massage at the moment.");
      return;
    }
    llMessageLinked(LINK_ROOT, testTrainerNotClient, "", client = llDetectedKey(0));
  }
  experience_permissions(key avi) {
    llMessageLinked(LINK_ROOT, getMasseur, "|" + llGetDisplayName(avi), avi);
  }
  experience_permissions_denied(key avi, integer reason) {
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != registerTrainers &&
	chan != testTrainerNotClientPass &&
	chan != testTrainerNotClientFail &&
	chan != testHudCheckPass &&
	chan != testHudCheckFail &&
	chan != massageReady &&
	chan != resetTable &&
	chan != clearTrainers) return;
    switch (chan) {
    case massageReady: {
      integer i = llSubStringIndex(msg,"|");
      key c = (key) llGetSubString(msg, i+1, -1);
      llSetText("In use by "+llGetDisplayName(c), <0,1,1>, 1);
      inUse = TRUE;
      break;
    }
    case resetTable: {
      if (has_trainers) {
	llSetText("Trainer available.\nClick for a massage.", <0,1,1>,1);
	llSetLinkPrimitiveParamsFast(LINK_THIS,
				     [PRIM_TEXTURE, 0,"console-a", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-a-norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-a-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      } else {
	llSetText("No trainers.", <0,1,1>,1);
	llSetLinkPrimitiveParamsFast(LINK_THIS,
				     [PRIM_TEXTURE, 0,"console-nt", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-nt-norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-nt-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      }
      inUse = FALSE;
      break;
    }
    case testTrainerNotClientPass: {
      llMessageLinked(LINK_ROOT, testHudCheck, "", client);
      break;
    }
    case testHudCheckPass: {
      llRequestExperiencePermissions(client, "");
      break;
    }
    case testHudCheckFail: {
      client = NULL_KEY;
      llSay(0, "Please wear the SPS HUD.");
      llMessageLinked(LINK_ROOT, signalReset, "", NULL_KEY);
      break;
    }
    case testTrainerNotClientFail: {
      client = NULL_KEY;
      llSay(0, "There are no other trainers available to give a massage at the moment.");
      llMessageLinked(LINK_ROOT, signalReset, "", NULL_KEY);
      break;
    }
    case registerTrainers: {
      if (!has_trainers && !inUse) llSetText("Trainer available.\nClick for a massage.", <0,1,1>,1);
      has_trainers = TRUE;
      break;
    }
    case clearTrainers: {
      if (has_trainers && !inUse) llSetText("No trainers.", <0,1,1>,1);
      client = NULL_KEY;
      has_trainers = FALSE;
      break;
    }
    default: break;
    }
  }
}

