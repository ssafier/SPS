#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

vector target = <-0.25,0,1.6>;
rotation target_rot = ZERO_ROTATION;
vector offset = ZERO_VECTOR;
list offset_cache;
string cached_animation;

vector lifter_pos = ZERO_VECTOR;
rotation lifter_rot = ZERO_ROTATION;
vector spotter_pos = ZERO_VECTOR;
rotation spotter_rot = ZERO_ROTATION;

integer spotter_link;

// precompute parameters to update sit position
integer link_num;
float fAdjust;
string sit_anim;

integer initialized = FALSE;

key read_handle;
// -----------------------------------------------
updateSitTarget(vector pos, rotation rot) {
  llLinkSitTarget(LINK_THIS, pos, rot);
  llSetLinkPrimitiveParamsFast(link_num,
			       [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) ,
				PRIM_ROT_LOCAL, rot]);
}

// -----------------------------------------------
checkUpdateSitTarget(vector t, rotation r) {
  debug(t);
  debug(target);
  if (t != target || r != target_rot) updateSitTarget(target = t, target_rot = r);
}

// ------------------------------
initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  spotter_link = -1;
  debug(objectPrimCount);
  while(currentLinkNumber <= objectPrimCount) {
    debug(currentLinkNumber);
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME, PRIM_DESC]);
    debug((string) params[0] + " " + (string) params[1]);
    switch((string) params[0]) {
    case "spotter prim": {
      spotter_link = currentLinkNumber;
      break;
    }
    default: break;
    }
    ++currentLinkNumber;
  }
  if (spotter_link == -1) llSay(0, "Cannot find spotter.");
  llSetLinkPrimitiveParamsFast(LINK_THIS,
			       [PRIM_SIT_FLAGS,
				//				SIT_FLAG_ALLOW_UNSIT |
				SIT_FLAG_SCRIPTED_ONLY]);
}

// -------------------
vector getCachedOffset(string a, vector offset) {
  integer l = llGetListLength(offset_cache);
  integer i;
  for (i = 0; i < l; i += 2) {
    if (a == (string) offset_cache[i]) {
      return (vector)(string) offset_cache[i+1];
    }
  }
  return offset;
}

// -------------------
updateCachedOffset(string a, vector offset) {
  integer l = llGetListLength(offset_cache);
  integer i;
  for (i = 0; i < l; i += 2) {
    if (a == (string) offset_cache[i]) {
      offset_cache = llListReplaceList(offset_cache, [(string) offset], i+1, i+1);
      return;
    }
  }
  offset_cache = [a, offset] + offset_cache;
}

// -------------------
default {
  on_rez(integer x) {
    initialize();
  }
  
  state_entry() {
    initialize();
    target = <-0.25,0,1.6>;
    offset = ZERO_VECTOR; 
    offset_cache = [];
    llLinkSitTarget(LINK_THIS, target + offset, ZERO_ROTATION);
  }
  
  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_ROOT);
    if (sitTest == 1) {
      vector size = llGetAgentSize(avi);
      fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
      integer linkNum = llGetNumberOfPrims();
      link_num = -1;
      while(linkNum && link_num == -1) {
	if (avi == llGetLinkKey(linkNum))
	  link_num = linkNum;
	else
	  --linkNum;
      }
      offset = ZERO_VECTOR;
      read_handle = llReadKeyValue((string) avi + "+RACK");
      llMessageLinked(LINK_SET, InUse, llGetDisplayName(avi), avi);
      llMessageLinked(LINK_THIS, getLeaf, (string) returnPosLeaf + "+" + sInitiateStand +"|" + sit_anim+"-STAND", avi);
      llMessageLinked(LINK_THIS, disallowTrainer, (string) avi, avi);
    }
  }
    
  dataserver(key h, string data) {
    switch(h) {
    case read_handle: {
      read_handle = NULL_KEY;
      if (llGetSubString(data,0,0) == "1") {
	offset_cache = llParseString2List(llGetSubString(data,2,-1),["|", ":"],[]);
      }
      break;
    }
    default: break;
    }
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != sitLifter &&
	chan != getPosFromConfig &&
	chan != getPosForEquipment &&
	chan != returnPosKeepAnim &&
	chan != returnPosLeaf &&
	chan != incrementLifterPos) return;
    GET_CONTROL;
    switch (chan) {
    case sitLifter: {
      POP(sit_anim);
      llRequestExperiencePermissions(xyzzy, "");
      break;
    }
    case getPosFromConfig: {
      UPDATE_NEXT(getLeaf);
      PUSH_CNTRL(returnPosLeaf);
      break;
    }
    case getPosForEquipment: {
      UPDATE_NEXT(getLeaf);
      PUSH_CNTRL(returnPosKeepAnim);
      break;
    }
    case incrementLifterPos: {
      string o;
      POP(o);
      offset += (vector) o;
      updateSitTarget(target = target + (vector) o, target_rot);
      break;
    }
    case returnPosKeepAnim:
    case returnPosLeaf: {
      debug("return leaf 0");
      string animation;
      if (cached_animation != "") updateCachedOffset(cached_animation, offset);
      POP(animation);
      if (animation == "[time out]") {
	animation = "";
	PUSH("[RESET]");
      } else if (animation == "STRING") {
	animation = "";
      } else {
	cached_animation = animation;
	string popper;
	POP(popper);
	lifter_pos = (vector) popper;
	POP(popper);
	lifter_rot = (rotation) popper;
	POP(popper);
	spotter_pos = (vector) popper;
	POP(popper);
	spotter_rot = (rotation) popper;
	if (chan == returnPosKeepAnim) {
	  PUSH(animation);
	} else {
	  checkUpdateSitTarget(lifter_pos + offset, lifter_rot);       
	  debug("|" + (string) spotter_pos + "|" + (string) spotter_rot);
	  llMessageLinked(spotter_link, positionSitter2,
			  "|" + (string) spotter_pos + "|" + (string) spotter_rot, xyzzy);
	}
      }
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
}
