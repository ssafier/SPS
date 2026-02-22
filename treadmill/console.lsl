#include "controlstack.h"
#include "evolve/sps.h"

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
      llMessageLinked(from, 0, "", "fw_addbox : Label : Treadmill : 0, 0, 16, 1 : a=center;c=yellow;w=none");
      llMessageLinked(LINK_THIS, 0, "Treadmill", "fw_data: Label");

      llMessageLinked(from, 0, "", "fw_addbox : Heart  : Treadmill : 0, 1, 6, 1 : a=left;c=red;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Speed  : Treadmill : 7, 1, 9, 1 : a=center;c=green;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Power  : Treadmill : 0, 2, 6, 1 : a=center;c=cyan;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Time  : Treadmill : 7, 2, 9, 1 : a=center;c=magenta;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Three  : Treadmill : 0, 3, 2, 1 : a=left;c=green;w=none");      
      llMessageLinked(from, 0, "", "fw_addbox : Six  : Treadmill : 2, 3, 2, 1 : a=left;c=green;w=none");      
      llMessageLinked(from, 0, "", "fw_addbox : Nine  : Treadmill : 4, 3, 2, 1 : a=left;c=green;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Twelve  : Treadmill : 6, 3, 3, 1 : a=left;c=green;w=none");      
      llMessageLinked(from, 0, "", "fw_addbox : Fifteen  : Treadmill : 9, 3, 3, 1 : a=left;c=green;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : Menu  : Treadmill : 12, 3, 4, 1 : a=left;c=orange;w=none");      
      llMessageLinked(LINK_THIS, 0, "0:00:00", "fw_data:Time");
      llMessageLinked(LINK_THIS, 0, "0 kM/H", "fw_data:Speed");
      llMessageLinked(LINK_THIS, 0, "0 W", "fw_data:Power");
      llMessageLinked(LINK_THIS, 0, "0 BPM", "fw_data:Heart");
      llMessageLinked(LINK_THIS, 0, "3", "fw_data:Three");
      llMessageLinked(LINK_THIS, 0, "6", "fw_data:Six");
      llMessageLinked(LINK_THIS, 0, "9", "fw_data:Nine");
      llMessageLinked(LINK_THIS, 0, "12", "fw_data:Twelve");
      llMessageLinked(LINK_THIS, 0, "15", "fw_data:Fifteen");
      llMessageLinked(LINK_THIS, 0, "Menu", "fw_data:Menu");
      break;
    }
    default: {
	  break;
	}
    }
  }
}
