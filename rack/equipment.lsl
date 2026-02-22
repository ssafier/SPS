#include "controlstack.h"
#include "evolve/sps.h"

#define NOTECARD_NAME ".equipment"

#define LENGTH 3.5
#define SPACING 0.01
#define SIDE_OFFSET 0.45

float diameter;
integer count;
rotation ref_rot;
integer weight;

key lifter;
integer handle;

// equipment
list support_bar_1;
list support_bar_2;
list support_1;
list support_2;
list pole1;
list pole2;
list pole3;
list pole4;
list pullup;
integer bench;

float rack_y;

key note_handle;
integer initialized = FALSE;

#define COUNT 6
//exercise|string|vector><rotation|back/front/inside+z|z|vector><rotation|vector><rotation
#define STRIDE 10
#define NAME 0 
#define BAR 1
#define BAR_ROT 2
#define BAR_OFFSET 3
#define BAR_ATTACH_ROT 4
#define HOLDER_BAR 5
#define HOLDER_Z 6
#define SUPPORT 7
#define BENCH_POS 8
#define BENCH_ROT 9

list exercises;

// ------------------------------
list find(string workout) {
  integer i;
  integer l = llGetListLength(exercises);
  for(i = 0; i < l; i += STRIDE) {
    if ((string) exercises[i+NAME] == workout) return llList2List(exercises,i,i+STRIDE);
  }
  return [];
}

// ------------------------------
initEquipment() {
  if (initialized) return;
  initialized = TRUE;
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    float back_y;

    bench = -1;
    pole1 = pole2 = pole3 = pole4 = pullup =
      support_bar_1 = support_bar_2 = support_1 =  support_2 = [];

    //debug(objectPrimCount);
    while(currentLinkNumber <= objectPrimCount) {
      //debug(currentLinkNumber);
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME, PRIM_DESC]);
      //debug((string) params[0] + " " + (string) params[1]);
      list desc = llParseStringKeepNulls((string) params[1], ["+"], []);
      integer n = (integer)(string)desc[0];
      switch((string) params[0]) {
      case "rack side": {
	vector loc = (vector)(string)desc[1] ;
	rotation rot = (rotation)(string)desc[2] ;
	vector size = (vector)(string)desc[3];
	float offset_x = size.x / -2;
	vector local = loc;
	if (n == 2) { 
	  local.x = loc.x - offset_x;
	  pole4 = [currentLinkNumber, local, rot];
	  local.x = loc.x + offset_x;
	  pole1 = [currentLinkNumber, local, rot];
	} else if (n == 1) { 
	  local.x = loc.x - offset_x;
	  pole3 = [currentLinkNumber, local, rot];
	  local.x = loc.x + offset_x;
	  pole2 = [currentLinkNumber, local, rot];
	}
	break;
      }
      case "horizontal support": {
	switch(n) {
	case 1: {
	  support_bar_1 = [currentLinkNumber, (vector)(string)desc[1] , (rotation)(string)desc[2] ];
	  break;
	}
	case 2: {
	  support_bar_2 = [currentLinkNumber, (vector)(string)desc[1] , (rotation)(string)desc[2] ];
	  break;
	}
	default: break;
	}       
	break;
      }
      case "holder": {
	switch(n) {
	case 1: {
	  support_1 = [currentLinkNumber, (vector)(string)desc[1] , (rotation)(string)desc[2] ];
	  break;
	}
	case 2: {
	  support_2 = [currentLinkNumber, (vector)(string)desc[1] , (rotation)(string)desc[2] ];
	  break;
	}
	default: break;
	}
      }
      case "Rack": {
	vector loc = (vector)(string)desc[1] ;
	rotation rot = (rotation)(string)desc[2];
	vector size = (vector)(string)desc[3];
	vector offset;
	offset.x = size.x / 2;
	rack_y = size.y;
	offset.z = size.z / 2;
	loc = loc + offset;
	vector local = loc;
	pullup = [currentLinkNumber, local, rot];
	break;
      }
      case "bp incline seat": {
	bench = currentLinkNumber;
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }
    if ((pullup == []) ||
	(bench == -1) ||
	(support_bar_1 == []) ||
	(support_bar_2 == []) ||
	(pole1 == []) ||
	(pole2 == []) ||
	(pole3 == []) ||
	(pole4 == []) ||
	(support_1 == []) ||
	(support_2 == [])) {
      llOwnerSay("Equipment initialization failed. " + llDumpList2String(pullup, " ") +
		 " support " +
		 llDumpList2String(support_bar_1, " ") + " support " +
		 llDumpList2String(support_bar_2, " ") + " pole1 " +
		 llDumpList2String(pole1, " ") + " pole2 " +
		 llDumpList2String(pole2, " ") + "pole3 " +
		 llDumpList2String(pole3, " ") + " pole4 " +
		 llDumpList2String(pole4, " ") + " support " +
		 (string) support_1 + " support " +
		 (string) support_2 + " bench " + (string) bench
		 );
    }
}

// ------------------------------
default {
  on_rez(integer x) {
    initEquipment();
  }
  state_entry() {
    initEquipment();
    exercises = [];
    llSay(0, "Reading equipment file...");
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }
  
  dataserver(key request, string data)  {
    debug(data);
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	debug(line);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF) {
	  if (line != "") {
	    list l = llParseString2List(line, ["|"], []);
	    switch(llToLower((string) l[0])) {
	    case "exercise": {
	      debug("exercise");
	      list p = llList2List(l,1,-1);
	      if (llGetListLength(p) == COUNT) {		
//exercise|string|vector><rotation|vector><rot|back/front+z|z|vector><rotation|vector><rotation
		string hld = (string) p[3];
		integer idx = llSubStringIndex(hld, " ");
		string temp = llGetSubString(hld, 0, idx - 1);
		integer hbar = -1;
		if (temp == "front") {
		  hbar = 0;
		} else if (temp == "back") {
		  hbar = 1;
		} else if (temp == "inside") {
		  hbar = 2;
		}
		float hz = (float) llGetSubString(hld, idx + 1, -1);
		idx = llSubStringIndex((string) p[1], ">");
		vector barp = (vector) llGetSubString((string) p[1], 0, idx) ;
		rotation barr = llEuler2Rot((vector) llGetSubString((string) p[1], idx+1, -1) * DEG_TO_RAD) ;
		idx = llSubStringIndex((string) p[2], ">");
		vector baroffset = (vector) llGetSubString((string) p[2], 0, idx) ;
		rotation barar = llEuler2Rot((vector) llGetSubString((string) p[2], idx+1, -1) * DEG_TO_RAD) ;
		idx = llSubStringIndex((string) p[5], ">");
		vector bp = (vector) llGetSubString((string) p[5], 0, idx)  ;
		rotation br = llEuler2Rot((vector) llGetSubString((string) p[5], idx+1, -1) * DEG_TO_RAD);
		debug("adding");
		exercises = exercises + [
					 (string) p[0],
					 barp, barr,
					 baroffset, barar,
					 hbar, hz,
					 (float)(string)p[4],
					 bp, br];
	      }
	      break;
	    }
	    default: break;
	    }
	  }
	} else {
	  debug("exercises "+llDumpList2String(exercises," "));
	  llSay(0,"Equipment loaded.");
	}
      }
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != ResetEquipment &&
	chan != ConfigureEquipment) return;
    //debug("on "+(string) chan);
    switch (chan) {
    case ResetEquipment: {
      //      llMessageLinked(bench, ResetBench, "", xyzzy);
      llMessageLinked(LINK_ALL_OTHERS, ClearLifter, "", xyzzy);
      llMessageLinked(LINK_THIS, ResetWorkout, "", xyzzy);
      llSetLinkPrimitiveParamsFast((integer) support_bar_1[0],
				   [PRIM_POS_LOCAL, (vector) support_bar_1[1],
				    PRIM_ROT_LOCAL, (rotation) support_bar_1[2]]);
      llSetLinkPrimitiveParamsFast((integer) support_bar_2[0],
				   [PRIM_POS_LOCAL, (vector) support_bar_2[1],
				    PRIM_ROT_LOCAL, (rotation) support_bar_2[2]]);
      llSetLinkPrimitiveParamsFast((integer) support_1[0],
				   [PRIM_POS_LOCAL, (vector) support_1[1],
				    PRIM_ROT_LOCAL, (rotation) support_1[2]]);
      llSetLinkPrimitiveParamsFast((integer) support_2[0],
				   [PRIM_POS_LOCAL, (vector) support_2[1],
				    PRIM_ROT_LOCAL, (rotation) support_2[2]]);
      llMessageLinked(LINK_THIS, resetWeights,"",xyzzy);
      llMessageLinked(LINK_SET, MoveBench, "<0, -2.6250, 0.625>|<0,0,0>", xyzzy);
      //llMessageLinked(LINK_SET, MoveBench, "<-3.75, -1.000000, 0.25>|<0,0,270>", xyzzy);
      break;
    }    
    case ConfigureEquipment: {
      //debug((string) chan + " " + msg);
      //debug("configure");
      GET_CONTROL;
      string setup;
      POP(setup);
      lifter = NULL_KEY;
      ref_rot = llGetRot() * llEuler2Rot(<0,0,90>*DEG_TO_RAD);;
      //debug(ref_rot);
      list exercise = find(setup);
      if (exercise == []) {
	llSay(0,"Cannot find exercise "+setup);
	return;
      }
      vector bar_position = (vector) exercise[BAR];
      rotation bar_rotation = (rotation) exercise[BAR_ROT];
      vector bar_offset = (vector) exercise[BAR_OFFSET];
      rotation bar_arot = (rotation) exercise[BAR_ATTACH_ROT];
      llMessageLinked(LINK_THIS, configureBar,
		      (string) bar_position + "|" +
		      (string) bar_rotation + "|" +
		      (string) bar_offset + "|" +
		      (string) bar_arot, NULL_KEY);
      vector s1 = (vector) support_1[1];
      vector s2 = (vector) support_2[1];
      rotation r = ZERO_ROTATION;
      s1.z = s2.z = (float) (string) exercise[HOLDER_Z];
      switch((integer) (string) exercise[HOLDER_BAR]) {
      case 0: {
	vector t = (vector) pole3[1];
	vector loc = (vector) support_1[1];
	vector size = (vector) support_1[3];
	s1.x = t.x - size.x-0.05;
	t = (vector) pole4[1];
	loc = (vector) support_2[1];
	size = (vector) support_2[3];
	s2.x = t.x - size.x-0.05;
	break;
      }
      case 1: {
	vector t = (vector) pole2[1];
	vector loc = (vector) support_1[1];
	vector size = (vector) support_1[3];
	s1.x = t.x + size.x + 0.25;
	t = (vector) pole1[1];
	loc = (vector) support_2[1];
	s2.x = t.x + size.x + 0.25;
	break;
      }
      case 2: {
	vector t = (vector) pole3[1];
	vector loc = (vector) support_1[1];
	vector size = (vector) support_1[3];
	s1.x = t.x - size.x - SIDE_OFFSET;
	t = (vector) pole4[1];
	loc = (vector) support_2[1];
	size = (vector) support_2[3];
	s2.x = t.x - size.x - SIDE_OFFSET;
	r = llEuler2Rot(<0,0,180>*DEG_TO_RAD);
	break;
      }
      default: break;
      }
      debug((string) s1 + " " + (string) s2);
      llSetLinkPrimitiveParamsFast((integer) support_1[0],
				   [PRIM_POS_LOCAL, s1,
				    PRIM_ROT_LOCAL, (rotation) support_1[4] * r]);
      llSetLinkPrimitiveParamsFast((integer) support_2[0],
				   [PRIM_POS_LOCAL, s2,
				    PRIM_ROT_LOCAL, (rotation) support_2[4] * r]);
      s1 = (vector) support_bar_1[1];
      s2 = (vector) support_bar_2[1];
      s1.z = s2.z = (float)(string) exercise[SUPPORT];
      llSetLinkPrimitiveParamsFast((integer) support_bar_1[0],
				   [PRIM_POS_LOCAL, s1]);
      llSetLinkPrimitiveParamsFast((integer) support_bar_2[0],
				   [PRIM_POS_LOCAL, s2]);
      //debug((string) exercise[BENCH_POS]);
      llMessageLinked(LINK_SET, MoveBench,
		      (string) exercise[BENCH_POS] + "|" + (string) exercise[BENCH_ROT],
		      xyzzy);     
      llMessageLinked(LINK_ALL_OTHERS, ReadyForLifter, "", xyzzy);
      PUSH(setup);
      NEXT_STATE;
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
