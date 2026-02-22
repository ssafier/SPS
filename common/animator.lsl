#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

#ifndef NOTECARD_NAME
#define NOTECARD_NAME ".animations"
#endif

#ifndef SPOTTER_NAME
#define SPOTTER_NAME "spotter"
#endif

integer spotter_prim;
integer lifter_prim;

// [name, pose1, pose2,...]
list poses;

key note_handle;
integer initialized = FALSE;

//----------------------

list translateAnimation(string a) {
  integer l = llGetListLength(poses);
  integer x = 0;
  while (x < l) {
    if ((string) poses[x] == a) return llList2List(poses, x+1, x+2);
    x += 3;
  }
  return [];
}
//----------------------

initialize() {
  if (initialized) return;
  initialized = TRUE;
  // find the animators
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  lifter_prim = spotter_prim = -1;
  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME]);
    if ((string) params[0] == SPOTTER_NAME) {
      spotter_prim = currentLinkNumber;
    }
    ++currentLinkNumber;
  }
  lifter_prim = LINK_THIS;
  if (lifter_prim == -1 || spotter_prim == -1) {
    llSay(0, "Error: cannot find animator prims");
  }
}

//----------------------
default {
  on_rez(integer x) {
    initialize();
  }
  
  state_entry() {
    initialize();
    llSay(0, "Reading animations file.");
    poses = [];
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }

  // pose|<sequence>|<sequence>
  // <sequence> = animation (?+flex(?: time))(? ~<sequence>)
  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF) {
	  if (line != "") {
	    list l = llParseString2List(line, ["|"], []);
	    switch(llToLower((string) l[0])) {
	    case "pose": {
	      list p = llList2List(l,1,-1);
	      if (llGetListLength(p) == 3) {
		poses = poses + p;
	      }
	      break;
	    }
	    default: break;
	    }
	  }
	} else {
	  llSay(0,"Animations loaded.");
	  //llOwnerSay("poses "+llDumpList2String(poses," "));
	}
      }
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != doAnimations)  return;
    debug("animate "+msg);
    list m = llParseStringKeepNulls(msg, ["|"], []);
   // translated this into sitters 1 and 2 then pass to the prim to execute
    list translation = translateAnimation((string) m[3]);
    if (msg == "" || (string) translation[0] == "" || (string) translation[1] == "") {
      llOwnerSay("Animation not found "+msg);
      return;
    }
    debug("translate "+llDumpList2String(translation, " "));
    // should handle animation sequences in animators
    llMessageLinked(lifter_prim, doAnimate, (string) m[4] + "|" + (string) translation[0], (key) m[1]);
#ifdef ALLOW_SINGLE
    debug("single? "+(string)(key)m[2]);
    if ((string) m[2] != "" && (key) m[2] != NULL_KEY)
#endif
    llMessageLinked(spotter_prim, doAnimate, (string) m[4] + "|" + (string) translation[1], (key) m[2]);
  }

  changed(integer f) {
    if (f & CHANGED_INVENTORY) {
      llResetScript();
    }
  }
}

