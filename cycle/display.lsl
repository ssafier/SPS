#include "include/controlstack.h"
#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif


default {
  state_entry() {
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Heart  : CycleUI : 0, 0, 6, 1 : a=left;c=red;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Speed  : CycleUI : 7, 0, 9, 1 : a=center;c=green;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Power  : CycleUI : 0, 1, 6, 1 : a=center;c=cyan;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Time  : CycleUI : 7, 1, 9, 1 : a=center;c=magenta;w=none");
      llMessageLinked(LINK_THIS, 0, "0:00:00", "fw_data:Time");
      llMessageLinked(LINK_THIS, 0, "0 kM/H", "fw_data:Speed");
      llMessageLinked(LINK_THIS, 0, "0 W", "fw_data:Power");
      llMessageLinked(LINK_THIS, 0, "0 BPM", "fw_data:Heart");
      break;
    }
    default: {
	  break;
	}
    }
  }
}
