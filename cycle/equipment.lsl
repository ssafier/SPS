#include "include/controlstack.h"
#include "include/sps.h"

key lifter;
integer handle;

// equipment
list front_wheel;
list cassette;
list frame;
list tri_left;
list tri_right;
list seat;
list bars;
list pedal;

integer initialized = FALSE;

// ------------------------------
initEquipment() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  pedal = front_wheel = cassette = frame = tri_left = tri_right = seat = bars = [];

  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME, PRIM_DESC]);
    list desc = llParseStringKeepNulls((string) params[1], ["+"], []);
    integer n = (integer)(string)desc[0];
    vector local = (vector)(string)desc[1] ;
    rotation rot = (rotation)(string)desc[2];

    switch((string) params[0]) {
    case "PedalGear":{
      pedal = [currentLinkNumber, local, rot];
      break;
    }
    case "Seat": {
      seat = [currentLinkNumber, local, rot];
      break;
    }
    case "tri left": {
      tri_left = [currentLinkNumber, local, rot];
      break;
    }
    case "tri right": {
      tri_right = [currentLinkNumber, local, rot];
      break;
    }
    case "bars": {
      bars = [currentLinkNumber, local, rot];
      break;
    }
    case "frame": {
      frame = [currentLinkNumber, local, rot];
      break;
    }
    case "front wheel": {
      front_wheel = [currentLinkNumber, local, rot];
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
}

// ------------------------------
default {
  on_rez(integer x) {
    initEquipment();
  }
  state_entry() {
    initEquipment();
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != ResetEquipment) return;
    switch (chan) {
    case ResetEquipment: {
      //      llMessageLinked(bench, ResetBench, "", xyzzy);
      llMessageLinked(LINK_ALL_OTHERS, WHEEL_OFF, "", xyzzy);
      llSetLinkPrimitiveParamsFast((integer) bars[0],
				   [PRIM_POS_LOCAL, (vector) bars[1],
				    PRIM_ROT_LOCAL, (rotation) bars[2]]);
      llSetLinkPrimitiveParamsFast((integer) tri_left[0],
				   [PRIM_POS_LOCAL, (vector) tri_left[1],
				    PRIM_ROT_LOCAL, (rotation) tri_left[2]]);
      llSetLinkPrimitiveParamsFast((integer) tri_right[0],
				   [PRIM_POS_LOCAL, (vector) tri_right[1],
				    PRIM_ROT_LOCAL, (rotation) tri_right[2]]);
      llSetLinkPrimitiveParamsFast((integer) seat[0],
				   [PRIM_POS_LOCAL, (vector) seat[1],
				    PRIM_ROT_LOCAL, (rotation) seat[2]]);
      break;
    }    
    default: break;
    }
  }

  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) {
      llResetScript();
    }
  }
}
