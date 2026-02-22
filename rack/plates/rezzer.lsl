#include "controlstack.h"
#include "evolve/sps.h"

#define NOTECARD_NAME ".weights"

#ifndef debug
#define debug(x)
#endif

#define LENGTH 3
#define SPACING 0.01

#define stride 4
#define material 0
#define WEIGHT 1
#define DIAMETER 2
#define HEIGHT 3
list weights2render;

key weight_set;
#define channel (integer)("0x"+llGetSubString((string) weight_set, -4, -1))

list weights;
list sizes;

float diameter;
integer weight_count;
vector bar_position;
rotation bar_rotation;
vector bar_offset;
rotation bar_arot;
rotation ref_rot;
integer weight;

float bar_length;

key lifter;
integer handle;

key note_handle;


// ------------------------------
// KEEP IN SYNC WITH BAR_WEIGHT
#define fixWeight(x) (((integer)((x)/5.0+0.5))*5)
integer getBar(integer str) {
  weight = 12;
  if (str > 15000) { diameter = 0.0634; bar_length = 10; return fixWeight(str - (weight = 250)); }
  else
    if (str > 5000) { diameter = 0.0508; bar_length = 6.2; return fixWeight(str - (weight = 100)); }
  else
    if (str > 500) { diameter = 0.03; bar_length = 4.5; return fixWeight(str - (weight = 25)); }
  //diameter = 0.0254;
  bar_length = 3.5;
  return fixWeight(str - 12);
}

// ------------------------------
integer getWeights(integer str) {
  weight_count = 0;
  weights = [];
  sizes = [];
  str = str / 2;
  debug((string) str);
  integer i;
  integer l = llGetListLength(weights2render);
  debug("render "+llDumpList2String(weights2render," "));
  debug("length "+(string) l);
  for (i = 0; i < l; i += stride) {
    while (str > (integer) weights2render[i+WEIGHT]) {
      weights = weights + [llDumpList2String(llList2List(weights2render, i, i + stride),"|")];
      sizes = sizes + [<(float) weights2render[i+DIAMETER], (float) weights2render[i+DIAMETER], (float) weights2render[i+HEIGHT]>];
      ++weight_count;
      str -= (integer) weights2render[i+WEIGHT];
      weight += ((integer) weights2render[i+WEIGHT]) * 2;
    }
  }

  return weight_count;
}

// ------------------------------
vector computeOffset(float barlen) {
  integer i;
  float zmax = 0;
  for (i = 0; i < weight_count; ++i) {
    vector temp = (vector) sizes[i];
    if (temp.y > zmax) zmax = temp.y; // z is the length of the weight, y is the height
  }
  return <1,(barlen / 2.0),zmax / 2.0>;
}

// ------------------------------
float computeLength() {
  integer i;
  float length = SPACING;
  for (i = 0; i < weight_count; ++i) {
    vector temp = (vector) sizes[i];
    length += temp.z + SPACING; // z is the length of the weight, y is the height
  }
  return length;
}

// ------------------------------
default {
  state_entry() {
    llSay(0, "Reading weight file...");
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }
  
  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF && line != "") {
	  list l = llParseString2List(line, ["|"], []);
	  weights2render += [(string) l[0], (integer) (string) l[1], (float) (string) l[2], (float) (string) l[3]];
	} else {
	  weights2render = llListSortStrided(weights2render, stride, weight, FALSE);
	  llSay(0, "Weight file loaded with "+(string) (llGetListLength(weights2render)/stride)+ "weights.");
	  state on;
	}
      }
    }
  }
}

state on {
  state_entry() { debug("on "+llDumpList2String(weights2render, " ")); }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != rezWeights && 
	chan != resetWeights &&
	chan != configureBar) return;
    debug("rezzing "+(string) chan);
    switch (chan) {
    case configureBar: {
      list params = llParseString2List(msg,["|"],[]);
      bar_position = (vector)(string)params[0];
      bar_rotation = (rotation)(string)params[1];
      bar_offset = (vector)(string)params[2];
      bar_arot = (rotation)(string)params[3];
      ref_rot = (rotation)(string)params[4] * llGetRot();
      break;
    }
    case resetWeights: {
      if (weight_set != NULL_KEY) {
	llSay(channel,"DIE");
      }
      weight_set = NULL_KEY;
      bar_position = bar_offset = ZERO_VECTOR;
      bar_rotation = bar_arot = ref_rot = ZERO_ROTATION;
      break;
    }
    case rezWeights: {
      integer strength = (integer) msg;
      lifter = xyzzy;
      debug("strength is "+msg);
      weight_count = getWeights(getBar(strength));
      debug("weight count "+(string)weight_count);
      integer c = (integer)("0x"+llGetSubString((string) llGetKey(),-4,-1));
      handle = llListen(c, "", NULL_KEY, "");
      debug(c);
      weight_set = llRezObjectWithParams("bar",
					 [ REZ_PARAM, c,
					   REZ_POS, llGetPos()+(bar_position*ref_rot), FALSE, FALSE,
					   REZ_VEL, ZERO_VECTOR, FALSE, FALSE,
					   REZ_ROT, bar_rotation * ref_rot, FALSE,
					   REZ_PARAM_STRING,
					   (string) bar_length + "|" + (string) diameter + "|" + (string) strength + "|" + (string) weight + "|" + (string) bar_offset + "|"+ (string) bar_arot]);
      
      break;
    }
    default: break;
    }
  }
  
  listen(integer chan, string name, key id, string msg) {
    debug("heard "+msg);
    llListenRemove(handle);
    handle = 0;
    state add_weights;
  }

  state_exit() {
    if (handle) llListenRemove(handle);
    handle = 0;
  }

  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) {
      llResetScript();
    }
  }
}

state add_weights {
  state_entry() {
    debug("add weights "+(string) weight_count);
    vector offset = computeOffset(LENGTH);
    debug(offset);
    vector pos;
    integer current = 0;
    while (current < weight_count) {
      debug(current);
      vector size = (vector) sizes[current];
      offset.y += size.z/2.0;
      pos = <0,offset.y,0>;
      llRezObjectWithParams("weight",
			    [ REZ_PARAM, weight_count,
			      REZ_POS, llGetPos() + ((bar_position + pos) * ref_rot), FALSE, FALSE,
			      REZ_VEL, ZERO_VECTOR, FALSE, FALSE,
			      REZ_ROT, llEuler2Rot(<90,0,0> *DEG_TO_RAD) * ref_rot, FALSE,
			      REZ_PARAM_STRING, (string) weight_set + "|" + (string) weights[current]]);
      pos = <0,-offset.y,0>;
      llRezObjectWithParams("weight",
			    [ REZ_PARAM, weight_count,
			      REZ_POS, llGetPos() + ((bar_position + pos) * ref_rot), FALSE, FALSE,
			      REZ_VEL, ZERO_VECTOR, FALSE, FALSE,
			      REZ_ROT, llEuler2Rot(<90,0,0> *DEG_TO_RAD) * ref_rot, FALSE,
			      REZ_PARAM_STRING, (string) weight_set + "|" + (string) weights[current]]);
      offset.y += (size.z/2.0 + SPACING);
      ++current;
    }
    llMessageLinked(LINK_THIS,
		    weightsRezzed,
		    "|" + (string) weight + "|" +(string) weight_set,
		    lifter);
    state on;
  }
}

