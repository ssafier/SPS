#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer initialized = FALSE;

key masseur;
key masseur_prim;
integer masseur_link;
key client;
key client_prim;
integer client_link;
vector client_pos;
rotation client_rot;

float fAdjust;
integer link_num; // link of the massuer
vector offset;

integer has_trainers;
integer dollars;

vector target = <-0.20000, 0.40000, 0.30000>;
rotation target_rot = ZERO_ROTATION;

// -----------------------------------------------
reset() {
  debug("reset");
  offset = ZERO_VECTOR;
  llMessageLinked(LINK_SET, resetTable, "", NULL_KEY);
  llMessageLinked(LINK_THIS, trainerAvailable, (string) masseur, masseur);
  llUnSit(masseur);
  llReleaseControls();
  client = masseur = NULL_KEY;
  dollars = 0;
  llSetTimerEvent(0);
}

// -----------------------------------------------
updateSitTarget(vector pos, rotation rot) {
  llLinkSitTarget(LINK_THIS, pos, rot);
  llSetLinkPrimitiveParamsFast(link_num,
			       [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) ,
				PRIM_ROT_LOCAL, rot]);
}

// -----------------------------------------------
checkUpdateSitTarget(vector t, rotation r) {
  if (t != target || r != target_rot) updateSitTarget(target = t + offset, target_rot = r);
}

// ---------------------------------------
initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  masseur_prim = llGetLinkKey(LINK_THIS);
  masseur_link = LINK_THIS;
  client_prim = NULL_KEY;
  client_link = -1;
  debug(objectPrimCount);
  while(currentLinkNumber <= objectPrimCount) {
    debug(currentLinkNumber);
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME, PRIM_DESC]);
    debug((string) params[0] + " " + (string) params[1]);
    if ((string) params[0] == "mat") {
      client_prim = llGetLinkKey(client_link = currentLinkNumber);
    }
    ++currentLinkNumber;
  }
  if (masseur_prim == NULL_KEY || client_prim == NULL_KEY) {
    llSay(0, "Error: masseur cannot find sitter prims");
  }
  llSetLinkPrimitiveParamsFast(LINK_THIS,
			       [PRIM_SIT_FLAGS,
				//				SIT_FLAG_ALLOW_UNSIT |
				SIT_FLAG_SCRIPTED_ONLY]);
}

string exportJson(string log) {
  return "{\"masseur\": \""+ (string) masseur +
    "\", \"client\": \""+(string) client +
    "\", \"dollars\": "+(string) dollars +
    ", \"entry\": " + log + "}";
}

// ---------------------------------------
default {
  on_rez(integer x) {
    initialized = FALSE;
    initialize();
  }
  state_entry() {
    initialize();
    offset = ZERO_VECTOR;
    llLinkSitTarget(LINK_THIS, target, ZERO_ROTATION);
  }

  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest == 1) {
      llMessageLinked(client_link, initializeSitter, "", client);
      masseur = avi;
      vector size = llGetAgentSize((key) masseur);
      fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
      integer linkNum = llGetNumberOfPrims();
      link_num = -1;
      while(linkNum && link_num == -1) {
	if (masseur == llGetLinkKey(linkNum))
	  link_num = linkNum;
	else
	  --linkNum;
      }
      llRegionSayTo(masseur, 0, "Touch the table to change pose or to stand.");
      llTakeControls(CONTROL_UP | CONTROL_DOWN | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_FWD | CONTROL_BACK, TRUE, FALSE);
      llMessageLinked(LINK_THIS, StartLog, "", client);
      llMessageLinked(LINK_SET, massageReady, (string) masseur + "|" + (string) client, client);
      llSetTimerEvent(300);
    } else {
      llInstantMessage(avi, "Cannot force agent " + llGetDisplayName(avi) + " to sit due to reason id: " + (string)sitTest);
      debug("init");
      reset();
      return;
    }
  }

  experience_permissions_denied(key avi, integer reason) {
    llInstantMessage(avi, "Experience permission required to sit " + llGetDisplayName(avi) + " to sit due to reason id: " + (string)reason);
  }

  timer() {
    dollars += 50;
    if (masseur != NULL_KEY)
      llSay((integer)("0x"+ llGetSubString((string) masseur, -8, -1)),"pay|50");
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != getMasseur &&
	chan != setTrainer &&
	chan != setTrainerFail &&
	chan != registerTrainers &&
	chan != clearTrainers &&
	chan != signalReset &&
	chan != returnLeaf &&
	chan != SaveMassage) return;
    GET_CONTROL;`
    switch (chan) {
    case setTrainer: {
      debug("set trainer "+(string) xyzzy);
      llRequestExperiencePermissions(xyzzy, "");
      break;
    }
    case setTrainerFail: {
      llSay(0, "Trainer is now unavailable.  Try again.");
      if (masseur) reset();
      break;
    }
    case registerTrainers: {
      has_trainers = TRUE;
      break;
    }
    case clearTrainers: {
      has_trainers = FALSE;
      break;
    }
    case getMasseur: {
      client = xyzzy;
      llMessageLinked(LINK_THIS, getTrainer, "", client);
      break;
    }
    case SaveMassage: {
      string log;
      POP(log);
      llMessageLinked(LINK_THIS,
		      saveLifterStats,
		      "|massage|" + exportJson(log),
		      masseur);	
      llSay((integer)("0x"+ llGetSubString((string) masseur, -8, -1)),"reset|");
      llSay((integer)("0x"+ llGetSubString((string) client, -8, -1)),"reset|");    
      debug("save");
      reset();
      break;
    }
    case returnLeaf: {
      string animation;
      POP(animation);
      string popper;
      if (animation == "STRING") {
	POP(popper);
	if (popper == "[STAND]") {
	  if (dollars > 0) {
	    llSay(0, "Saving massage to database.");
	    llMessageLinked(LINK_THIS, SaveLog,
			    (string) SaveMassage + "|3|0|0|31", client);
	  } else {
	    llMessageLinked(LINK_THIS, ResetLog, "", client);
	    reset();
	  }
	  return;
	}
      } else {
	POP(popper);
	vector masseur_pos = (vector) popper;
	POP(popper);
	rotation masseur_rot = (rotation) popper;
	POP(popper);
	client_pos = (vector) popper;
	POP(popper);
	client_rot = (rotation) popper;
	checkUpdateSitTarget(masseur_pos, masseur_rot);       
	llMessageLinked(client_link, positionSitter2,
			"|" + (string) client_pos + "|" + (string) client_rot, client);
	llMessageLinked(LINK_THIS, doAnimations,
			"animate|" + (string) masseur + "|" + (string) client + "|" + animation + "|" + (string) (afCache | afReplace),
			masseur);
      }
      PUSH(animation);
      NEXT_STATE;
      break;
    }
    case signalReset: {
      reset();
      break;
    }
    default: break;
    }
  }

// Events for keyboard control
#define changing(x) change & x
#define up changing(CONTROL_UP)
#define down changing(CONTROL_DOWN)
#define fwd changing(CONTROL_FWD)
#define back changing(CONTROL_BACK)
#define rot_left changing(CONTROL_ROT_LEFT)
#define rot_right changing(CONTROL_ROT_RIGHT)
#define left changing(CONTROL_LEFT)
#define right changing(CONTROL_RIGHT)

#define holding(x) held & x
#define start_up holding(up)
#define start_down holding(down)
#define start_fwd holding(fwd)
#define start_back holding(back)
#define start_rot_left holding(rot_left)
#define start_rot_right holding(rot_right)
#define start_left holding(left)
#define start_right holding(right)

#define end_up (held == 0) && (up)
#define end_down (held == 0) && (down)
#define end_fwd (held == 0) && (fwd)
#define end_back (held == 0) && (back)
#define end_rot_left (held == 0) && (rot_left)
#define end_rot_right (held == 0) && (rot_right)
#define end_left (held == 0) && (left)
#define end_right (held == 0) && (right)

#define edge change == 0
#define cont_up (edge) && (holding(CONTROL_UP))
#define cont_down (edge) && (holding(CONTROL_DOWN))
#define cont_fwd (edge) && (holding(CONTROL_FWD))
#define cont_back (edge) && (holding(CONTROL_BACK))
#define cont_rot_left (edge) && (holding(CONTROL_ROT_LEFT))
#define cont_rot_right (edge) && (holding(CONTROL_ROT_RIGHT))
#define cont_left (edge) && (holding(CONTROL_LEFT))
#define cont_right (edge) && (holding(CONTROL_RIGHT))

  control(key id, integer held, integer change) {
    debug((string) held + " " + (string) change);
    // do actual action depending on movement keys
    if ((start_down) || (cont_down)) {
      offset = offset - <0,0,0.01>;
    } else if ((start_up) || (cont_up)) {
      offset = offset + <0,0,0.01>;
    } else if ((start_fwd) || (cont_fwd)) {
      offset = offset + <0.01,0,0>;
    } else if ((start_back)  || (cont_back)) {
      offset = offset - <0.01,0,0>;
    } else if ((start_left) || (cont_left)) {
      offset = offset - <0,0.01,0>;
    } else if ((start_right)  || (cont_right)) {
      offset = offset + <0,0.01,0>;
    }
    updateSitTarget(target+offset, target_rot);
  }  
}
