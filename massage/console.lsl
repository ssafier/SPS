#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key masseur;
integer has_trainers;
integer inUse;
integer both_seated;
integer client_link;
integer display_link;

integer initialized;
initialize() {
  if (initialized) return;
  initialized = TRUE;
  integer objectPrimCount = llGetObjectPrimCount(llGetKey());
  integer currentLinkNumber = 0;
  display_link = -1;
  while(currentLinkNumber <= objectPrimCount) {
    list params = llGetLinkPrimitiveParams(currentLinkNumber,
					   [PRIM_NAME]);
    if ((string) params[0] == "console") {
      display_link = currentLinkNumber;
      return;
    }
    ++currentLinkNumber;
  }
  llSay(0, "Error: cannot find console");
}

default {
  on_rez(integer x) { initialized = FALSE; initialize(); }
  state_entry() {
    initialize();
    both_seated = has_trainers = inUse = FALSE;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != massageReady &&
	chan != registerTrainers &&
	chan != bothSeated &&	  
	chan != clearTrainers &&
	chan != resetTable) return;
    GET_CONTROL;
    switch (chan) {
    case registerTrainers: {
      if (!has_trainers && !inUse) {
	llSetLinkPrimitiveParamsFast(display_link,
				     [PRIM_TEXTURE, 0,"console-a", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-a- norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-a-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      }
      has_trainers = TRUE;
      break;
    }
    case clearTrainers: {
      if (has_trainers && !inUse) {
	llSetLinkPrimitiveParamsFast(display_link,
				     [PRIM_TEXTURE, 0,"console-nt", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-nt- norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-nt-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      }
      has_trainers = FALSE;
      break;
    }
    case massageReady: {
      integer i = llSubStringIndex(msg,"|");
      key masseur = (key) llGetSubString(msg,0,i-1);
      inUse = TRUE;
	llSetLinkPrimitiveParamsFast(display_link,
				     [PRIM_TEXTURE, 0,"console-iu", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-iu- norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-iu-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      break;
    }
    case resetTable: {
      both_seated = inUse = FALSE;
      llMessageLinked(LINK_SET, resetAnimationState,"|",NULL_KEY);
      if (has_trainers) {
	llSetLinkPrimitiveParamsFast(display_link,
				     [PRIM_TEXTURE, 0,"console-a", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-a- norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-a-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      } else {
	llSetLinkPrimitiveParamsFast(display_link,
				     [PRIM_TEXTURE, 0,"console-nt", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_NORMAL, 0, "console-nt- norm", <1,1,0>,ZERO_VECTOR,0,
				      PRIM_SPECULAR, 0, "console-nt-spec", <1,1,0>,ZERO_VECTOR,0, <1,0.5,0>, 60, 15]);
      }
      llResetOtherScript(".masseur");
      break;
    }
    case bothSeated: {
      string clink;
      POP(clink);
      client_link = (integer) clink;
      debug((string) llAvatarOnLinkSitTarget(LINK_THIS) + " " +
	    (string) llAvatarOnLinkSitTarget(client_link) + " " + (string) client_link);
      if (llAvatarOnLinkSitTarget(LINK_THIS) != NULL_KEY &&
	  llAvatarOnLinkSitTarget(client_link) != NULL_KEY) {
#ifdef fubar
	list l = llGetObjectDetails(llAvatarOnLinkSitTarget(LINK_THIS),[OBJECT_ROOT]);
	debug((string) l[0]);
	l = llGetObjectDetails(llAvatarOnLinkSitTarget(client_link),[OBJECT_ROOT]);
	debug((string) l[0]);
#endif
	both_seated = TRUE;
	llMessageLinked(LINK_THIS, getLeaf, ((string) returnLeaf) + "|Relax", xyzzy);
      } else {
	llMessageLinked(LINK_SET, signalReset, "", NULL_KEY);
      }
    }
    default: break;
    }
    NEXT_STATE;
  }
}
