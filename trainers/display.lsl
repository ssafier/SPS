#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

string trainer;
integer handle;
integer channel;
key agent;

default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    llSetText(llGetObjectDesc() + " trainer registry.", <1,0,0>,1);
    channel = (integer) ("0x"+llGetSubString((string) llGetLinkKey(LINK_THIS), -4, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }
  touch_start(integer x) {
    integer link = llDetectedLinkNumber(0);
    if (link != llGetLinkNumber()) return;
    llListenControl(handle, TRUE);
    llDialog(agent = llDetectedKey(0), "Do you want to be a trainer?",["Yes", "No"], channel);
    llSetTimerEvent(15);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    debug((string)xyzzy);
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    switch (msg) {
    case "Yes": { llMessageLinked(LINK_THIS, testHudCheck, "", agent); break; }
    case "No": { llMessageLinked(LINK_THIS, removeTrainer, "|"+(string) agent, agent); break; }
    default: break;
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != testHudCheckPass &&
	chan != testHudCheckFail) return;
    debug((string)xyzzy);
    switch (chan) {
    case testHudCheckPass: {
      llRequestExperiencePermissions(agent, "");
      break;
    }
    case testHudCheckFail: {
      llSay(0, "To be a trainer, please wear the SPS HUD.");
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
  }
  experience_permissions(key avi) {
    llMessageLinked(LINK_THIS, addTrainer, "|" + (string) avi, avi);
  }
  experience_permissions_denied(key avi, integer reason) {
    llRegionSayTo(avi, 0, "SPS experience is required to play.");
  }
}

