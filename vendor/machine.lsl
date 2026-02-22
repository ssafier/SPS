#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#define resetTime 1.0
#define displayTime 15.0
#define userTime 60.0

integer channel;
integer buyer_channel;
key buyer;
integer handle;
key http_handle;

integer initialized = FALSE;

#define stride 3
#define supName 0
#define supTexture 1
#define supCost 2

list items;
integer cItemLen;
integer supIndex;

initialize() {
  if (initialized) return;
  initialized = TRUE;
  items = [
	   "Training HUD", "vendor-hud", 0,
	   "trEnergy", "vendor-trenergy", 500,
	   "Creatine", "vendor-creatine", 25,
	   "Menthol", "vendor-menthol", 10,
	   "Protein shake", "vendor-protein", 20
	   ];
  supIndex = 0;
  cItemLen = llGetListLength(items);
}

#define nextSup()  supIndex += stride; if (supIndex >= cItemLen) supIndex = 0
#define prevSup() if ((supIndex = supIndex - stride) < 0) supIndex = cItemLen - stride
#define displaySup() llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, 1,(string) items[supIndex+supTexture], <1,1,0>,ZERO_VECTOR,0, PRIM_NORMAL, 1,(string) items[supIndex+supTexture]+"-norm", <1,1,0>,ZERO_VECTOR,0, PRIM_SPECULAR, 1, (string) items[supIndex+supTexture]+"-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);

default {
  on_rez(integer x) {
    initialize();
  }
  
  state_entry() {
    initialize();
    llSetClickAction(CLICK_ACTION_TOUCH);
    displaySup();
    llSetTimerEvent(displayTime);
  }

  state_exit() {
  }

  timer() {
    llSetTimerEvent(0);
    nextSup();
    displaySup();
    llSetTimerEvent(displayTime);
  }
  
  touch_start(integer x) {
    vector point = llDetectedTouchUV(0);
    if (point.x < 0.398 || point.x > 0.443) return;
    if (point.y < 0.548 || point.y > 0.577) return;

    if (point.x < 0.415) {
      llSetTimerEvent(0);
#ifdef BETA
      if ((supIndex == 0) && (llDetectedGroup(0) == 0)) {
	llSay(0, "HUDs are available to BETA testers only.  Please make sure SPS Dev is your active group.  Contact Corwin if you want to apply.");
	return;
      }
#endif
      llRequestExperiencePermissions(llDetectedKey(0), "");
    } else if (point.x > 0.42) {
      llSetTimerEvent(0);
      if (point.y < 0.559) { prevSup(); } else { nextSup(); }
      displaySup();
      llSetTimerEvent(userTime);
      }
  }

  experience_permissions(key avi) {
    integer cmd = supIndex / stride;
    switch (cmd) {
    case 0: { // hud
      llMessageLinked(LINK_THIS, requestHUD, "", avi);
      break;
    }
    default: {
      buyer_channel = (integer)("0x"+ llGetSubString((string) avi, -8, -1));
      buyer = avi;
      state purchase;
    }
    }
  }
  
  experience_permissions_denied(key avi, integer reason) {
    llRegionSayTo(avi, 0, "You must accept this experience to play SPS.  SPS uses experiences for animation, to sit you on various equipment, and allow for keyboard control.");
    llSetTimerEvent(displayTime);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != restartTimer) return;
    llSetTimerEvent(resetTime);
  }
}

state purchase {
  state_entry() {
    channel = (integer) ("0x"+llGetSubString((string) llGetKey(), -8,-1));
    handle = llListen(channel, "", NULL_KEY, "");
    integer cmd = supIndex / stride;
    switch (cmd) {
    case trEnergy: { // tren
      llSay(buyer_channel, "debit|500|1|"+(string)channel);
      break;
    }
    case creatine: { // creatine
      llSay(buyer_channel, "debit|25|2|"+(string)channel);
      break;
    }
    case menthol: { // menthol
      llSay(buyer_channel, "debit|10|3|"+(string)channel);
      break;
    }
    case protein_shake: { // protein
      llSay(buyer_channel, "debit|20|4|"+(string)channel);
      break;
    }
    default: {
      state default;
      break;
    }
    }
    llSetTimerEvent(5);
  }
  state_exit() {
    llSetTimerEvent(0);
    llListenRemove(handle);
  }
  timer() {
    llSetTimerEvent(0);
    llSay(0, "Please wear the SPS HUD to buy from the vending machine.");
    state default;
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    llSetTimerEvent(0);
    list cmd = llParseString2List(msg, ["|"],[]);
    if ((integer)(string)cmd[0] == 0) {
      llSay(0, (string) cmd[1]);
      state default;
    }
    llMessageLinked(LINK_THIS, doMenu, (string) confirmPurchase + "|" + (string) cmd[1] + "|" + "Yes+No",buyer);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != confirmPurchase) return;
    if (msg != "|Yes") {
      llSay(0, "Purchase canceled.");
      state default;
    }
    integer snum = supIndex / stride;
    http_handle = llHTTPRequest(SERVER + "sps/purchase/"+(string) xyzzy+"/"+(string) snum, [], "");
  }

  http_response(key r, integer status, list meta, string body) {
    if (r != http_handle) return;
    if (status != 200) {
      llSay(0, "Server error, try again.");
      state default;
    }
    string status = llJsonGetValue(body, ["status"]);
    switch (status) {
    case "success": {
      llSay(0,"Purchase completed.  Your HUD will update in a few seconds.");
      llSay(buyer_channel,"reset|");
      integer snum = supIndex / stride;
      if (snum == 1) {
	llStartAnimation("trEnergy");
      }
      break;
    }
    case "unknown": {
      llSay(0, "You are not a known player.");
      break;
    }
    case "active": {
      llSay(0, "Supplement is already active.  Please wait until it has expired before buying more.");
      break;
    }
    case "insufficient": {
      llSay(0, "You have not earned enough Trainer Dollars to purchase this item..");
      break;
    }      
    default: llSay(0, "Unknown status: "+status);
    }
    state default;
  }
}
