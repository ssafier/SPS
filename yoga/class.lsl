#include "include/controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key trainer_console;
integer delay;

integer class_channel;
key class_mat;
integer in_class;

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
    state find_master_mat;
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

state find_master_mat {
  state_entry() {
    in_class = FALSE;
    class_channel = 0;
    handle = llListen(TrainerResponseChannel, "[SPS] Trainer Console", trainer_console, "");
    llListenControl(handle, FALSE);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch (chan) {
    case getLeafCheckClass: {
      if (in_class) {
	llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|InClass", xyzzy);
      } else if (class_channel != 0) {
	llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|ClassAvailable", xyzzy);
      } else {
	llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|<root node>", xyzzy);
      }
      break;
    }
    case checkClass: {
      if (in_class) return;
      llListenControl(handle, TRUE);
      llRegionSayTo(trainer_console, TrainerQueryChannel, "get-yoga-class|");
      break;
    }
    case joinClass: {
      class_handle = llListen(class_channel, "[SPS] Yoga Instructor", class_mat, "");
      in_class = TRUE;
      llRegionSayTo(class_mat, class_channel, "join|");
      break;
    }
    case leaveClass: {
      llRegionSayTo(class_mat, class_channel, "leave|");
      in_class = FALSE;
      llListenRemove(class_handle);
      class_handle = 0;
      break;
    }
    case endClass: {
      if (in_class) {
	if (class_channel != 0) llRegionSayTo(class_mat, class_channel, "leave|");
	llListenRemove(class_handle);
	class_handle = 0;
      }
      in_class = FALSE;
      class_channel = 0;
      class_mat = NULL_KEY;
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
	class_mat = (key) (string) cmd[1];
	class_channel = (integer) (string) cmd[2];
	break;
      }
      case "no-class": {
	class_channel = 0;
	class_mat = NULL_KEY;
	break;
      }
      default: break;
      }
      break;
    }
    case class_channel: {
      if (class_channel == 0) return;
      list cmd = llParseString2List(msg,["|"],[]);
      switch ((string) cmd[0]) {
      case "animate": {
	llMessageLinked(LINK_THIS, returnLeaf, "|STRING|"+(string) cmd[1], NULL_KEY);
	break;
      }
      case "leave": {
	in_class = FALSE;
	llListenRemove(class_handle);
	class_handle = 0;
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
