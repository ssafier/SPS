#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef showOffset
#define showOffset(x)
#endif

key yogi;
float fatigue;
float integrity;

integer channel;
integer handle;

// ---------------------
default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    channel = (integer)("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }

  touch_start(integer x) {
    debug("touch");
    if (llAvatarOnSitTarget() == NULL_KEY) {
      debug("do test");
      llMessageLinked(LINK_THIS, testHudCheck, "", yogi = llDetectedKey(0));
    } else if (llDetectedKey(0) == yogi) {
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|<root node>", yogi);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != testHudCheckPass &&
	chan != testHudCheckFail &&
	chan != isTrainerPass  &&
	chan != isNotTrainer &&
	chan != ResetWorkout) return;
    switch(chan) {
    case ResetWorkout: {
      yogi = NULL_KEY;
      break;
    }
    case testHudCheckPass: {
      debug("pass");
      if (llAgentInExperience(yogi)) {
	llMessageLinked(LINK_THIS, testTrainer, (string) yogi, yogi);
      } else {
	llRegionSayTo(yogi, 0, "You must be a member of the SPS experience to use the treadmill.");
	yogi = NULL_KEY;
      }
      break;
    }
    case isTrainerPass: {
      debug("trainer");
      llListenControl(handle, TRUE);
      llDialog(yogi, "Do you you want to instruct a yoga class?",
	       ["Yes", "No"], channel);
      llSetTimerEvent(20);
      break;
    }
    case isNotTrainer: {
      yogi = NULL_KEY;
      llSay(0, "You must be a registered trainer to run a yoga class.");
      break;
    }
    case testHudCheckFail: {
      yogi = NULL_KEY;
      llSay(0, "Please wear the SPS HUD.");
      break;
    }
    default: break;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    if (msg == "Yes") llMessageLinked(LINK_THIS, Yoga, "", yogi);
  }

  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    yogi = NULL_KEY;
  }
}


