#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

// sml data
integer strength;

key lifter;
key handle;
integer h;
// ---------------------------------------

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != requestHUD &&
	chan != transferSML) return;
    switch (chan) {
    case requestHUD: {
      handle = llReadKeyValue((string) (lifter = xyzzy));
      break;
    }
    case transferSML: {
      debug(msg);
      GET_CONTROL;
      string answer;
      POP(answer);
      if (answer == "Yes") {
	lifter = xyzzy;
	state get_sml;
      } else if (answer == "No") {
	lifter = xyzzy;
	strength = 500;
	state give_hud;
      } else {
	llMessageLinked(LINK_THIS, restartTimer, "", NULL_KEY);
      }
      break;
    }
    default: break;
    }
  }
  dataserver(key h, string data) {
    if (h != handle) return;
    handle = NULL_KEY;
    if (llGetSubString(data,0,0) == "0") {
      llCreateKeyValue((string) lifter, VERSION);
      llMessageLinked(LINK_THIS,
		      doMenu,
		      (string) transferSML + "|To transfer SML strength to SPS, wear the SML training HUD and click YES|Yes+No",
		      lifter);
      llRegionSayTo(lifter,0,"Join the SML Group Chat: secondlife:///app/group/b84aebe8-3b90-00fa-e467-56a2e33b6a82/about");
      return;
    }
    strength = 500;
    state give_hud;
  }
}

state get_sml {
  state_entry() {
    key bee = llRezObjectWithParams("bee",
			    [ REZ_PARAM, 1,
			      REZ_POS, llGetPos() + <0.01,0.01,0.01>, FALSE, FALSE,
			      REZ_PARAM_STRING, (string) lifter]);
    h = llListen((integer)("0x"+llGetSubString((string) bee, -4, -1)),"", NULL_KEY, "");
    llSetTimerEvent(20);
  }

  timer() {
    llSetTimerEvent(0);
    llRegionSayTo(lifter,0,"Cannot get strength.  Are you wearing the SML HUD?");
    llListenRemove(h);
    llMessageLinked(LINK_THIS, restartTimer, "", NULL_KEY);
    state default;
  }

  state_exit() {
    llSetTimerEvent(0);
    llListenRemove(h);
  }
  
  listen(integer chan, string name, key xyzzy, string sMsg) {
    llSetTimerEvent(0);    debug( sMsg );
    strength = 0;
    integer stamina = 0;
    integer level = 0;
    integer hud_version = 0;
    integer i = 0;
    list lTemp = llParseString2List(sMsg,["|"],[]);
    for(i=0;i<llGetListLength(lTemp);i++) {
      list lTemp2 = llParseString2List(llList2String(lTemp, i), [":"], [] );
      integer _val = (integer) (string)lTemp2[1];
      switch((string)lTemp2[0]) {
      case  "STRENGTH": { strength = (integer)(_val + 500.05);	break;  }
      case "STAMINA": { stamina = _val;	break;   }
      case "LEVEL": { level = _val; break;  }
      case "VERSION": { hud_version = _val; break; }
      default: break;
      }
    }
    /////////////////////////////////////////////////////////
    llRegionSayTo(lifter,0,"SML strength + 500 bonus: "+(string) strength +".");
    state give_hud;
  }
}

#define makeJSON(str, xp) "{ \"xp\": "+(string) (xp) +", "+ "\"strength\":"+ (string) (str) + "}"
state give_hud {
  state_entry() {
    float arms = ((float) strength) * 0.05;
    float armsRest = arms - (integer) arms;
    float chest =  ((float) strength) * 0.20;
    float chestRest = chest - (integer) chest;
    float back =  ((float) strength) * 0.25;
    float backRest = back - (integer) back;
    float legs =  ((float) strength) * 0.40;
    float legsRest = legs - (integer) legs;
    float core =  ((float) strength) * 0.10;
    float coreRest = core - (integer) core;
    string output = "{\"lifter\": \""+(string) lifter + "\""
    +  ", \"arms\": "+ makeJSON((integer) arms, armsRest)
    + ", \"chest\": "+ makeJSON((integer) chest, chestRest)
    + ", \"core\": "+ makeJSON((integer) core, coreRest)
    + ", \"back\": "+ makeJSON((integer) back, backRest)
    + ", \"legs\": "+ makeJSON((integer) legs, legsRest) + "}";
    debug("save");
    llMessageLinked(LINK_THIS,
		    saveLifterStats,
		    (string) giveHUD+"|register|"+output,
		    lifter);
    llSetTimerEvent(10);
  }
  timer() {
    llSay(0, "Giving the hud has failed.  Try again.");
    state default;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != giveHUD) return;
    debug("give");
    GET_CONTROL;
    string status;
    POP(status);
    string message = "";
    switch(status) {
    case "server": {
      break;
    }
    case "error": {
      break;
    }
    case "create": message = "SPS Player created.  Enjoy!";
    case "updated": if (message == "") message = "Player strength updated.";
    case "ok": {
      if (message != "") llRegionSayTo(lifter, 0, message);
      llGiveAgentInventory(
			   lifter,
			   "SPS "+VERSION,
			   ["SPS HUD", "SPS Instructions"],
			   []);
      break;
    }
    default: break;
    }
    UPDATE_NEXT(restartTimer);
    NEXT_STATE;
    state default;
  }
}
