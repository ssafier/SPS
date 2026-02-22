#define debug(x)
default {
  state_entry() {
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    while(currentLinkNumber <= objectPrimCount) {
      debug(currentLinkNumber);
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME, PRIM_DESC,
					      PRIM_POS_LOCAL, PRIM_ROT_LOCAL,
					      PRIM_SIZE]);
      if ((string) params[0] == "spotter prim") {
	llSetLinkPrimitiveParamsFast(currentLinkNumber,[
							PRIM_POS_LOCAL, <0,0,1>,
							PRIM_COLOR, ALL_SIDES, <1,1,1>, 1]);
      }
      ++currentLinkNumber;
    }
  }
}
