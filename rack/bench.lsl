#ifndef debug
#define debug(x)
#endif

#define ResetBench 1006

#define FlatBench 2000
#define InclineBench 2001
#define MoveBench 2002

vector home;
rotation home_rot;

list base;
list support2;
list support3;
list back;

list incline_back;
list incline_support2;
integer inclined;


default {
  state_entry() {
    home = llGetLocalPos();
    home_rot = llGetLocalRot();
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    base = support2 = support3 =   back = [];
    list params = llGetLinkPrimitiveParams(LINK_THIS, [PRIM_DESC]);
    params = llParseStringKeepNulls((string) params[0], ["+"],[]);
				     
    vector lpos = (vector) (string) params[1];

    debug(lpos);
    while(currentLinkNumber <= objectPrimCount) {
      debug(currentLinkNumber);
      params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME, PRIM_DESC]);
      debug((string) params[0] + " " + (string) params[1]);
      list desc = llParseStringKeepNulls((string) params[1], ["+"], []);
      debug((string)desc[1]);
      integer n = (integer)(string)desc[0];
      switch((string) params[0]) {
      case "bench base": {
	base = [currentLinkNumber, (vector)(string)desc[1] - lpos, (rotation)(string)desc[2]];
	break;
      }
      case "bp support": {
	if (n == 3) {
	  support3 = [currentLinkNumber, (vector)(string)desc[1] - lpos, (rotation)(string)desc[2]];
	} else if (n == 2) {
	  support2 = [currentLinkNumber, (vector)(string)desc[1] - lpos, (rotation)(string)desc[2],
		      (vector)(string)desc[4]];
	  vector size = (vector)(string)desc[4];
	  size.z = 0.75;
	  incline_support2 = [currentLinkNumber,
			      <-0.934593, 0.000000, -0.055542>,
			      <0.000000, 0.139173, 0.000000, 0.990268>,
			      size];
	}
	break;
      }
      case "bp incline back": {
	back = [currentLinkNumber, (vector)(string)desc[1] - lpos, (rotation)(string)desc[2]];
	incline_back = [currentLinkNumber,
			<-1.089630, 0.000000, 0.739136>,
			<0.000000, 0.382684, 0.000000, 0.923880>];
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }
    if ((base == []) ||
	(support2 == []) ||
	(support3 == []) ||
	(back == [])) {
      llOwnerSay("bench press initialization failed.");
    }
    inclined = FALSE;
  }

  touch(integer x) {
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case ResetBench: {
      inclined = FALSE;
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_POS_LOCAL,home,
				    PRIM_ROT_LOCAL, ZERO_ROTATION]);
      llSetLinkPrimitiveParamsFast((integer) base[0],
				   [PRIM_POS_LOCAL, home + (vector) base[1],
				    PRIM_ROT_LOCAL,  (rotation) base[2]]);
      llSetLinkPrimitiveParamsFast((integer) support2[0],
				   [PRIM_POS_LOCAL, home + (vector) support2[1],
				    PRIM_ROT_LOCAL,  (rotation) support2[2]]);
      llSetLinkPrimitiveParamsFast((integer) support3[0],
				   [PRIM_POS_LOCAL, home + (vector) support3[1],
				    PRIM_ROT_LOCAL,  (rotation) support3[2],
				    PRIM_SIZE, (vector) support3[3]]);
      llSetLinkPrimitiveParamsFast((integer) back[0],
				   [PRIM_POS_LOCAL, home + (vector) back[1],
				    PRIM_ROT_LOCAL,  (rotation) back[2]]);
      break;
    }
    case InclineBench: {
      list params = llGetLinkPrimitiveParams(LINK_THIS,
					   [PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE]);
    if (inclined) return;
    inclined = TRUE;
    rotation lrot = (rotation)params[1];
    vector lpos = (vector)params[0];
    llSetLinkPrimitiveParamsFast((integer) incline_back[0],
				 [PRIM_POS_LOCAL, ((vector) incline_back[1] * lrot) + lpos,
				  PRIM_ROT_LOCAL,  (rotation) incline_back[2]*lrot]);
    llSetLinkPrimitiveParamsFast((integer) incline_support2[0],
				 [PRIM_POS_LOCAL, ((vector) incline_support2[1] * lrot) + lpos,
				  PRIM_ROT_LOCAL,  (rotation) incline_support2[2] * lrot,
				  PRIM_SIZE, (vector) incline_support2[3]]);
      break;
    }
    case FlatBench: {
      list params = llGetLinkPrimitiveParams(LINK_THIS,
					     [PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE]);
      if (inclined == 0) return;
      inclined = FALSE;
      rotation lrot = (rotation)params[1];
      vector lpos = (vector)params[0];
      llSetLinkPrimitiveParamsFast((integer) back[0],
				   [PRIM_POS_LOCAL, ((vector) back[1] * lrot) + lpos,
				    PRIM_ROT_LOCAL,  (rotation) back[2]*lrot]);
      llSetLinkPrimitiveParamsFast((integer) support2[0],
				   [PRIM_POS_LOCAL, ((vector) support2[1] * lrot) + lpos,
				    PRIM_ROT_LOCAL,  (rotation) support2[2] * lrot,
				    PRIM_SIZE, (vector) support2[3]]);
      break;
    }
    case MoveBench: {
      list params = llParseString2List(msg, ["|"],[]);
      vector lpos = (vector) (string) params[0];
      rotation lrot = (rotation)(string) params[1];
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_POS_LOCAL,lpos, PRIM_ROT_LOCAL, lrot]);
      if (inclined) {
	llSetLinkPrimitiveParamsFast((integer) incline_back[0],
				     [PRIM_POS_LOCAL, ((vector) incline_back[1] * lrot) + lpos,
				      PRIM_ROT_LOCAL,  (rotation) incline_back[2]*lrot]);
	llSetLinkPrimitiveParamsFast((integer) incline_support2[0],
				     [PRIM_POS_LOCAL, ((vector) incline_support2[1] * lrot) + lpos,
				      PRIM_ROT_LOCAL,  (rotation) incline_support2[2] * lrot,
				      PRIM_SIZE, (vector) incline_support2[3]]);
      } else {
	llSetLinkPrimitiveParamsFast((integer) back[0],
				     [PRIM_POS_LOCAL, ((vector) back[1] * lrot) + lpos,
				      PRIM_ROT_LOCAL,  (rotation) back[2]*lrot]);
	llSetLinkPrimitiveParamsFast((integer) support2[0],
				     [PRIM_POS_LOCAL, ((vector) support2[1] * lrot) + lpos,
				      PRIM_ROT_LOCAL,  (rotation) support2[2] * lrot,
				      PRIM_SIZE, (vector) support2[3]]);
      }
      llSetLinkPrimitiveParamsFast((integer) support3[0],
				   [PRIM_POS_LOCAL, ((vector) support3[1] * lrot) + lpos,
				    PRIM_ROT_LOCAL,  (rotation) support3[2]*lrot]);
      llSetLinkPrimitiveParamsFast((integer) base[0],
				   [PRIM_POS_LOCAL, ((vector) base[1] * lrot) + lpos,
				    PRIM_ROT_LOCAL,  (rotation) base[2]*lrot]);
      break;
    }
    default: break;
    }
  }
}
