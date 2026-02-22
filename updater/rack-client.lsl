#include "evolve/update.h"

#ifndef debug
#define debug(x)
#endif

list scripts;
list objects;
list textures;
list animations;
list notecards;

integer initialized = FALSE;

integer handle;
integer scriptkey;
integer update_channel;

initialize() {
  if (initialized) return;
  initialized = TRUE;
  scripts = objects = textures = animations = notecards = [];
  integer i;
  integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
  for (i = 0; i < count; ++i) {
    string name = llGetInventoryName(INVENTORY_SCRIPT, i);
    if (name != llGetScriptName()) {
      if (llSubStringIndex(name, "FURWARE text") == -1)
	scripts = [name] + scripts;
      else
	scripts = scripts + [name];
      llSetScriptState(name,FALSE);
    }
  }
  count = llGetInventoryNumber(INVENTORY_ANIMATION);
  for (i = 0; i < count; ++i) {
    animations += [llGetInventoryName(INVENTORY_ANIMATION, i)];
  }
  count = llGetInventoryNumber(INVENTORY_OBJECT);
  for (i = 0; i < count; ++i) {
    objects += [llGetInventoryName(INVENTORY_OBJECT, i)];
  }
  count = llGetInventoryNumber(INVENTORY_TEXTURE);
  for (i = 0; i < count; ++i) {
    textures += [llGetInventoryName(INVENTORY_TEXTURE, i)];
  }
  count = llGetInventoryNumber(INVENTORY_NOTECARD);
  for (i = 0; i < count; ++i) {
    notecards += [llGetInventoryName(INVENTORY_NOTECARD, i)];
  }
}

default {
  on_rez(integer x) {
    initialize();
  }

  state_entry() {
    initialize();
    if (llListFindList(objects,["weight"]) != -1) state listening;
  }
  changed(integer x) {
    if (x & CHANGED_INVENTORY) {
      llSleep(1);
      integer i;
      integer count = llGetInventoryNumber(INVENTORY_OBJECT);
      for (i = 0; i < count; ++i) {
	if (llGetInventoryName(INVENTORY_OBJECT, i) == "weight") {
	  initialized = FALSE;
	  initialize();
	  if (llListFindList(objects,["weight"]) != -1) state listening;
	}
      }
    }
  }
}

state listening {
  changed(integer x) {
    if (x & CHANGED_INVENTORY) {
      llSleep(1);
      integer i;
      integer count = llGetInventoryNumber(INVENTORY_OBJECT);
      for (i = 0; i < count; ++i) {
	if (llGetInventoryName(INVENTORY_OBJECT, i) == "weight") {
	  return;
	}
      }
      initialized = FALSE;
      state default;
    }
  }
  state_exit() { llListenRemove(handle); }
  state_entry() {
    llSay(0,"Starting power rack.");
    integer l= llGetListLength(scripts);
    integer i;
    for (i = 0; i < l; ++i) {
      llSetScriptState((string)scripts[i],TRUE);
      llResetOtherScript((string)scripts[i]);
    }
    handle = llListen(UPDATE_CHANNEL, "SPS Update Bee", NULL_KEY, "");
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list cmd = llParseString2List(msg, ["|"],[]);
      switch ((string) cmd[0]) {
      case "locate": {
	llRegionSayTo((key) cmd[1], (integer) cmd[2],
		      llGetObjectName() + "|" + llGetObjectDesc() + "|"+ (string) llGetPos() + "|" + (string) llGetKey());
	break;
      }
      case "update": {
	scriptkey = (integer) cmd[1];
	update_channel = (integer) cmd[2];
	state doUpdate;
	break;
      }
      default: break;
      }
  }
}

state doUpdate {
  state_entry() {
    handle = llListen(update_channel, "SPS Update Bee", NULL_KEY, "");
    llSetRemoteScriptAccessPin(scriptkey);
    llSay(-update_channel, "ready");
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list cmd = llParseString2List(msg, ["|"],[]);
    switch ((string) cmd[0]) {
    case "version": {
      llSetObjectDesc((string) cmd[1]);
      break;
    }
    case "stopscripts": {
      integer i = llGetListLength(scripts);
      while (i > 0) {
	--i;
	llSetScriptState((string)scripts[i],FALSE);
      }
      break;
    }
    case "delete": {
      switch ((string) cmd[1]) {
      case "script": {
	if (llListFindList(scripts,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "notecard": {
	if (llListFindList(notecards,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "texture": {
	if (llListFindList(textures,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "animation": {
	if (llListFindList(animations,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "object": {
	if (llListFindList(objects,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      default: break;
      }
      llSay(-update_channel,"deleted");
      break;
    }
    case "restart": {
      initialized = FALSE;
      llSetRemoteScriptAccessPin(0);
      state default;
    }
    default: break;
    }
  }
  changed(integer f) {
    if (f & CHANGED_INVENTORY) llSay(-update_channel,"received");
  }
}
