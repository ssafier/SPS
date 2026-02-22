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

default {
  state_entry() {
    both_seated = has_trainers = inUse = FALSE;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Status : Points : 0, 1, 16, 3 : border=tlbr;a=center;c=cyan;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Label : Points : 0, 0, 16, 1 : a=center;c=cyan;w=none");
      llMessageLinked(LINK_THIS, 0, "Massage Table", "fw_data: Label");
      llMessageLinked(LINK_THIS, 0, "No Trainers", "fw_data:Status");
      break;
    }
    default: {
      if (chan != massageReady &&
	  chan != registerTrainers &&
	  chan != bothSeated &&	  
	  chan != clearTrainers &&
	  chan != resetTable) return;
	  GET_CONTROL;
	  switch (chan) {
	  case registerTrainers: {
	    if (!has_trainers && !inUse)
	      llMessageLinked(LINK_THIS, 0, "Available", "fw_data:Status");
	    has_trainers = TRUE;
	    break;
	  }
	  case clearTrainers: {
	    if (has_trainers && !inUse)
	      llMessageLinked(LINK_THIS, 0, "No Trainers", "fw_data:Status");
	    has_trainers = FALSE;
	    break;
	  }
	  case massageReady: {
	    integer i = llSubStringIndex(msg,"|");
	    key masseur = (key) llGetSubString(msg,0,i-1);
	    inUse = TRUE;
	    llMessageLinked(LINK_THIS, 0, llGetDisplayName(masseur), "fw_data:Status");
	    break;
	  }
	  case resetTable: {
	    both_seated = inUse = FALSE;
	    if (has_trainers) {
	      llMessageLinked(LINK_THIS, 0, "Available", "fw_data:Status");
	    } else {
	      llMessageLinked(LINK_THIS, 0, "No Trainers", "fw_data:Status");
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
	  break;
	}
    }
  }
}
