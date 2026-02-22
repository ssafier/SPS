#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key trainer_console;
integer delay;

integer class_channel;
integer joined;
integer dollars_earned;

string animation;

integer handle;
integer class_handle;

default {
  on_rez(integer x) { llResetScript(); }
  state_entry() {
    handle = 0;
    llSetTimerEvent(delay = 1);
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);
  }
  sensor(integer ignore) {
    llSetTimerEvent(0);
    llSay(0,"Attached to trainer console.");
    trainer_console = llDetectedKey(0);
    state use_master_mat;
  }
  timer() {
    if (delay < 1800) {
      llSetTimerEvent(0);
      delay = delay * 2;
      if (delay > 1800) delay = 1800;
      llSetTimerEvent(delay);
    }
    llSensor("[SPS] Trainer Console",NULL_KEY,SCRIPTED,96,PI);    
  }
}

state use_master_mat {
  state_entry() {
    class_channel = 0;
    handle = llListen(TrainerResponseChannel, "[SPS] Trainer Console", trainer_console, "");
    llListenControl(handle, FALSE);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch (chan) {
    case animateClass: {
      animation = msg;
      llShout(class_channel, "animate|"+animation);
      break;
    }
    case checkClass: {
      if (class_channel == 0) {
	llListenControl(handle, TRUE);
	llRegionSayTo(trainer_console, TrainerQueryChannel, "start-yoga-class|"+(string) xyzzy);
      }
      break;
    }
    case endClass: {
      if (class_channel != 0) llShout(class_channel, "leave|");
      llListenRemove(class_handle);
      llRegionSayTo(trainer_console, TrainerQueryChannel, "end-yoga-class|"+(string) xyzzy);
      class_handle = 0;
      class_channel = 0;
      break;
    }
    case saveClass: {
      GET_CONTROL;
      PUSH(dollars_earned);
      dollars_earned = 0;
      joined = 0;
      NEXT_STATE;
      break;
    }
    case incrementClassPay: {
      dollars_earned += joined;
      llSay((integer)("0x"+ llGetSubString((string) xyzzy, -8, -1)), "pay|"+(string) joined);
      break;
    }
    default: break;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    switch (chan) {
    case TrainerResponseChannel: {
      llListenControl(handle, FALSE);
      list cmd = llParseString2List(msg,["|"],[]);
      switch ((string) cmd[0]) {
      case "class": {
	class_channel = (integer) (string) cmd[2];
	class_handle = llListen(class_channel, "[SPS] Yoga Mat", NULL_KEY, "");
	joined = 0;
	dollars_earned = 0;
	animation = "Arm";
	break;
      }
      default: break;
      }
      break;
    }
    case class_channel: {
      if (class_channel == 0) return;
      debug(msg);
      list cmd = llParseString2List(msg,["|"],[]);
      switch ((string) cmd[0]) {
      case "join": {
	joined++;
	llRegionSayTo(xyzzy, class_channel, "animate|"+animation);
	break;
      }
      case "leave": {
	joined--;
	break;
      }
      default: break;
      }
      break;
    }
    default: break;
  }
  }
}
