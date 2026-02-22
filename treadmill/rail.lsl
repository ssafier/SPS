#include "evolve/sps.h"

default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
    llSetText("",<.1,.6,.1>,1);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != ME) return;
    llSetText(msg,<.1,.6,.1>,1);
  }
  touch_start(integer x) {
    llMessageLinked(LINK_SET,MY_TOUCH,"", llDetectedKey(0));
  }
}
