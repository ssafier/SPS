#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer channel;
integer handle;
integer link;

#define SayToHud(x) llRegionSayTo(xyzzy, lifter_channel, (string)(x))

default {
  state_entry() {
    channel = (integer)("0x"+ llGetSubString((string) llGetKey(), -8, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != testHudCheck) return;
    GET_CONTROL;
    integer lifter_channel = (integer)("0x"+ llGetSubString((string) xyzzy, -8, -1));
    llListenControl(handle, TRUE);
    llSetTimerEvent(1.5);
    link = from;
    debug("say");
    SayToHud("version|" + (string) channel);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    debug("pass "+msg);
    if (msg != ("|" + VERSION)) {
      llSay(0, "You have an old version of the hud.  Please take a new hud from the vendor.");
      llMessageLinked(link, testHudCheckFail, msg, xyzzy);
    } else {
      llMessageLinked(link, testHudCheckPass, msg, xyzzy);
    }
  }

  timer() {
    llSetTimerEvent(0);
    debug("fail");
    llListenControl(handle, FALSE);
    llMessageLinked(link, testHudCheckFail, "", NULL_KEY);
  }
}
