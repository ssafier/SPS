#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key target;

default {
  on_rez(integer x) {
    if (x == 0) llResetScript();
  }
  state_entry() {
    llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
  }
  
  run_time_permissions(integer f) {
    if (f & PERMISSION_CHANGE_LINKS) { state rezzing; } else llSay(0, "These weights will not work.  Please rerez them and accept link permissions");
  }
}

state rezzing {
  on_rez(integer x) {
    if (x == 0) state default;
    list params = llParseString2List(llGetStartString(),["|"],[]);
    target = (key)(string) params[0];
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIZE,
				  <(float)(string)params[3],
				    (float)(string)params[3],
				    (float)(string)params[4]>,
				  PRIM_COLOR, ALL_SIDES, <1,1,1>, 1, 
				  PRIM_TEXTURE, ALL_SIDES, (string)params[1], <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_NORMAL, ALL_SIDES,  (string)params[1] + "-norm", <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_SPECULAR, ALL_SIDES,  (string)params[1] + "-shiny", <1,1,1>, ZERO_VECTOR, 0, <0,0,0>,0,0,
				    PRIM_TEXTURE, 0, (string) params[2],  <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_NORMAL, 0,  (string) params[2] + "-norm", <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_SPECULAR, 0,  (string) params[2] + "-shiny", <1,1,1>, ZERO_VECTOR, 0,<0,0,0>,0,0,
				    PRIM_TEXTURE, 2, (string) params[2],  <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_NORMAL, 2,  (string)  params[2] + "-norm", <1,1,1>, ZERO_VECTOR, 0,
				    PRIM_SPECULAR, 2,  (string) params[2] + "-shiny", <1,1,1>, ZERO_VECTOR, 0, <0,0,0>,0,0]);				  
      llCreateLink(target, FALSE);
  }
}
