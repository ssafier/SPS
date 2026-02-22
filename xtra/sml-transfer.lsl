#include "controlstack.h"
#define LOCAL
#include "evolve/mat.h"

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
  state_entry() {
    llSetText("Touch to transfer SML strength to SPS", <1,1,1>,1);
  }
  touch_start(integer x) {
    llRequestExperiencePermissions(lifter = llDetectedKey(0), "");
  }
  experience_permissions(key avi) {
    state start;
  }
  experience_permissions_denied(key avi, integer x) {
  }
}

state start {
  state_entry() {
    key bee = llRezObjectWithParams("bee",
			    [ REZ_PARAM, 1,
			      REZ_POS, llGetPos() + <0.01,0.01,0.01>, FALSE, FALSE,
			      REZ_PARAM_STRING, (string) lifter]);
    h = llListen((integer)("0x"+llGetSubString((string) bee, -4, -1)),"", NULL_KEY, "");
    llSetTimerEvent(20);
  }

  timer() {
    llRegionSayTo(lifter,0,"Cannot get strength.  Are you wearing the SML HUD?");
    llListenRemove(h);
  }

  state_exit() {
    llSetTimerEvent(0);
    llListenRemove(h);
  }
  
  listen(integer chan, string name, key xyzzy, string sMsg) {
    llSetTimerEvent(0);
    debug( sMsg );

    /////////////////////////////////////////////////////////
    // link_message second parameter number is 55002 for receive.
    // have to parse sMsg, you don't need to modify this area
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
      case  "STRENGTH": {
	strength = _val + 500;
	break;
      }
      case "STAMINA": {
	stamina = _val;
	break;
      }
      case "LEVEL": {
	level = _val;
	break;
      }
      case "VERSION": {
	hud_version = _val;
	break;
      }
      default: break;
      }
    }
    /////////////////////////////////////////////////////////
    llRegionSayTo(lifter,0,"SML strength + 500 bonus: "+(string) strength +".");
    state arms;
  }
}

state arms {
  state_entry() {
    float arms2 = ((float) strength) * 0.05;
    float rest = arms2 - (integer) arms2;
    string r = SERVER + "sps/update/"  + llEscapeURL((string) lifter) + "?strength="+(string)((integer)arms2) + "&xp="+(string) rest + "&fatigue=0&bodypart=1";
    handle = llHTTPRequest(r,[],"");
  }
  http_response(key request, integer status, list meta, string body) {
    if (request == handle) state core;
  }
}

state core {
  state_entry() {
    float core2 =  ((float) strength) * 0.10;
    float rest = core2 - (integer) core2;
    string r = SERVER + "sps/update/"  + llEscapeURL((string) lifter) + "?strength="+(string)((integer)core2) + "&xp="+(string) rest + "&fatigue=0&bodypart=2";
    handle = llHTTPRequest(r,[],"");
  }
  http_response(key request, integer status, list meta, string body) {
    if (request == handle) state legs;
  }
}


state legs {
  state_entry() {
    float legs2 =  ((float) strength) * 0.40;
    float rest = legs2 - (integer) legs2;
    string r = SERVER + "sps/update/"  + llEscapeURL((string) lifter) + "?strength="+(string)((integer)legs2) + "&xp="+(string) rest + "&fatigue=0&bodypart=16";
    handle = llHTTPRequest(r,[],"");
    
  }
  http_response(key request, integer status, list meta, string body) {
    if (request == handle) state back;
  }
}


state back {
  state_entry() {
    float back2 =  ((float) strength) * 0.25;
    float rest = back2 - (integer) back2;
    string r = SERVER + "sps/update/"  + llEscapeURL((string) lifter) + "?strength="+(string)((integer)back2) + "&xp="+(string) rest + "&fatigue=0&bodypart=8";
    handle = llHTTPRequest(r,[],"");

  }
  http_response(key request, integer status, list meta, string body) {
    if (request == handle) state chest;
  }
}


state chest {
  state_entry() {
    float chest2 =  ((float) strength) * 0.20;
    float rest = chest2 - (integer) chest2;
    string r = SERVER + "sps/update/"  + llEscapeURL((string) lifter) + "?strength="+(string)((integer)chest2) + "&xp="+(string) rest + "&fatigue=0&bodypart=4";
    handle = llHTTPRequest(r,[],"");
  }
  http_response(key request, integer status, list meta, string body) {
      if (request == handle) {
	llSay(0, "done");
	state default;
      }
  }
}
