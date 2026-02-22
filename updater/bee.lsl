#include "evolve/update.h"

#ifndef debug
#define debug(x)
#endif

integer channel;
integer handle;
list responses;
list equipment;

list filter(string name, float v) {
  integer l = llGetListLength(equipment);
  integer i;
  list keep = [];
  for (i = 0; i < l; i += 4) {
    if ((string) equipment[i] == name &&
	(float) equipment[i+1] < v) {
      keep += llList2List(equipment, i, i+3);
    }
  }
  return keep;
}

default {
  state_entry() {
    channel = (integer)("0x"+llGetSubString((string) llGetKey(), -5,-1));
    handle = llListen(channel,"",NULL_KEY,"");
    responses = [];
    llSetTimerEvent(5);
    llRegionSay(UPDATE_CHANNEL,"locate|"+(string)llGetKey()+"|"+(string) channel);
  }
  listen(integer channel, string name, key xyzzy, string msg) {
    responses += [msg];
  }
  timer() {
    llSetTimerEvent(0);
    llSay(0,"timer");
    integer l = llGetListLength(responses);
    integer i;
    equipment = [];
    for (i = 0; i < l; ++i) {
      list r = llParseString2List((string) responses[i], ["|"],[]);
      if (llListFindList(equipment,[(vector)(string)r[2]]) == -1) {
	equipment += [(string) r[0], (float)(string) r[1], (vector)(string) r[2], (key)(string)r[3]];
      }
    }
    equipment = filter(PowerRack, 0.2);
    llSay(0, llDumpList2String(equipment," "));
  }
}
