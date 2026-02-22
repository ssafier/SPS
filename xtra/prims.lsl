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
      string desc = (string) params[1];
      if (llSubStringIndex(desc,"+") != -1) {
	desc = llGetSubString(desc, 0, llSubStringIndex(desc,"+") - 1);
      }
      integer n = (integer) desc;
      switch((string) params[0]) {
      case "bench base":
      case "bp incline back":
      case "bp incline seat":
      case "horizontal support": {
	llSetLinkPrimitiveParamsFast(currentLinkNumber,
				     [PRIM_DESC,
				      desc + "+" +
				      (string)(vector)params[2] +"+" +
				      (string)(rotation)params[3]]);
	break;
      }
      case "holder":
      case "Rack":
      case "rack side": 
      case "bp support": {
	llSetLinkPrimitiveParamsFast(currentLinkNumber,
				     [PRIM_DESC,
				      desc + "+" +
				      (string)(vector)params[2] +"+" +
				      (string)(rotation)params[3] + "+" +
				      (string)(vector)params[4]]);
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }
  }
}
