#include "controlstack.h"
#include "evolve/sps.h"

#define GYM llGetObjectDesc()

#define NoPic TEXTURE_TRANSPARENT

#ifndef debug
#define debug(x)
#endif

list pic_links;
list current_trainers;
integer last;
integer cleared;
integer handle;

default {
  state_entry() {
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    integer one;
    integer two;
    integer three;
    integer four;
    integer five;

    debug(objectPrimCount);
    while(currentLinkNumber <= objectPrimCount) {
      debug(currentLinkNumber);
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME, PRIM_DESC]);
      debug((string) params[0] + " " + (string) params[1]);
      if ((string) params[0] == "pic") {
	switch((integer)(string)params[1]) {
	case 1: { one = currentLinkNumber; break; }
	case 2: { two = currentLinkNumber; break; }
	case 3: { three = currentLinkNumber; break; }
	case 4: { four = currentLinkNumber; break; }
	case 5: { five = currentLinkNumber; break; }
	default: break;
	}
      }
      ++currentLinkNumber;
    }
    pic_links = [one, two, three, four, five];
    cleared = FALSE;
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Trainer1 : TrainerBoard : 0, 0, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Client1 : TrainerBoard : 24, 0, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Trainer2 : TrainerBoard : 0, 1, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Client2 : TrainerBoard : 24, 1, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Trainer3 : TrainerBoard : 0, 2, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Client3 : TrainerBoard : 24, 2, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Trainer4 : TrainerBoard : 0, 3, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Client4 : TrainerBoard : 24, 3, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Trainer5 : TrainerBoard : 0, 4, 24, 1 : a=left;c=orange;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Client5 : TrainerBoard : 24, 4, 24, 1 : a=left;c=orange;w=none");
      
      break;
    }
    default: {
      if (chan != clearTrainers &&
	  chan != registerTrainers) return;
      switch (chan) {
      case clearTrainers: {
	if (!cleared) {
	  integer i = 0;
	  while (i < 5) {
	    llSetLinkTexture((integer) pic_links[i], NoPic, ALL_SIDES);
	    ++i;
	    llMessageLinked(LINK_THIS, 0, "", "fw_data:Trainer"+(string)i);
	    llMessageLinked(LINK_THIS, 0, "", "fw_data:Client"+(string)i);
	  }
	  llSetTimerEvent(0);
	}
	current_trainers = [];
	cleared = TRUE;
	break;
      }
      case registerTrainers: {
	llSetTimerEvent(0);
	debug("register "+msg);
	cleared = FALSE;
	if (handle == 0)
	  handle = llListen(TrainerResponseChannel, "[SPS] Trainer Console", xyzzy, "");
	else
	  llListenControl(handle, TRUE);
	llRegionSayTo(xyzzy, TrainerQueryChannel, "display|"); 
	break;
      }
      default: break;
      }
      break;
    }
    }
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list cmd = llParseStringKeepNulls(msg, ["|"], []);
    if ((string) cmd[0] != "tc") return;
    debug("heard "+msg);
    llListenControl(handle, FALSE);
    last = 0;
    current_trainers = llList2List(cmd, 1, -1);
    llSetTimerEvent(1);
  }
  
  timer() {
    llSetTimerEvent(0);
    integer i = last;
    integer n = 1;
    integer len = llGetListLength(current_trainers) / 2;
    integer fini =last + 5;
    if (fini > len) fini = len;
    key temp;
    while (i < fini) {
      llMessageLinked(LINK_THIS, 0,
		      llGetDisplayName((key) current_trainers[i*2]),
		      "fw_data:Trainer"+(string)n);
      temp = (key) current_trainers[i*2+1];
      if (temp == NULL_KEY)
	llMessageLinked(LINK_THIS, 0, "Available", "fw_data:Client"+(string)n);
      else if ((string) temp == "Yoga")
	llMessageLinked(LINK_THIS, 0, (string) temp + " class", "fw_data:Client"+(string)n);
      else
	llMessageLinked(LINK_THIS, 0, llGetDisplayName(temp), "fw_data:Client"+(string)n);
      llMessageLinked((integer)pic_links[n-1],
		      renderImage,
		      (string)(integer)pic_links[n-1],
		      (key) current_trainers[i*2]);
      ++n;
      ++i;
    }
    while (n < 6) {
      llMessageLinked(LINK_THIS, 0, "", "fw_data:Trainer"+(string)n);
      llMessageLinked(LINK_THIS, 0, "", "fw_data:Client"+(string)n);
      llSetLinkTexture((integer) pic_links[n-1], TEXTURE_TRANSPARENT, ALL_SIDES);
      ++n;
    }
    if (len > 5) {
      if (fini < len) last = fini; else last = 0;
      llSetTimerEvent(10);
    }
  }    
}

