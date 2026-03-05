#include "include/sps.h"
#include "include/update.h"

#ifndef debug
#define debug(x)
#endif

integer channel;
integer handle;
list responses;
list equipment;

integer index;
vector home;

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
    responses = [];
    llSetClickAction(CLICK_ACTION_TOUCH);
    llSay(0, "Touch to update SPS equipment.");
  }
  
  touch_start(integer x) {
    handle = llListen(channel,"",NULL_KEY,"");
    llSetTimerEvent(5);
    llRegionSay(UPDATE_CHANNEL,"locate|"+(string)llGetKey()+"|"+(string) channel);
  }

  listen(integer channel, string name, key xyzzy, string msg) {
    responses += [msg];
  }

  timer() {
    llSetTimerEvent(0);
    integer l = llGetListLength(responses);
    llSay(0,"timer "+(string) l);
    integer i;
    equipment = [];
    for (i = 0; i < l; ++i) { 
      list r = llParseString2List((string) responses[i], ["|"],[]);
      if (llListFindList(equipment,[(vector)(string)r[2]]) == -1) {
	equipment += [(string) r[0], (float)(string) r[1], (vector)(string) r[2], (key)(string)r[3]];
      }
    }
    equipment = filter(PowerRack, 0.6); // number is THIS version
    state update;
  }
}

state update {
  state_entry() {
    index = 0;
    home = llGetPos();
    if (index < llGetListLength(equipment))
      llMessageLinked(LINK_THIS, flyBee,
		      sUpdateEquipment + "+" + sIncrementUpdate + "|" +
		      (string)(vector)equipment[index + 2] + "|" +
		      (string)equipment[index] + "|" +
		      (string)(float)equipment[index + 1],
		      (key)equipment[index + 3]);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan  != incrementUpdate) return;
    index += 4;
    if (index < llGetListLength(equipment)) {
      llMessageLinked(LINK_THIS, flyBee,
		      sUpdateEquipment + "+" + sIncrementUpdate + "|" +
		      (string)(vector)equipment[index + 2] + "|" +
		      (string)equipment[index] + "|" +
		      (string)(float)equipment[index + 1],
		      (key)equipment[index + 3]);
    } else {
      llMessageLinked(LINK_THIS, flyBee, "|" + (string) home, NULL_KEY);
      
    }
  }    
}
