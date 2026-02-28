#define LENGTH 2.5
integer channel;
integer handle;
vector origin;

key data_key;
key die_key;

key lifter;
string animation;
integer update_offset;
vector offset;
rotation lrot;

list data;
integer outchan;

default {
  on_rez(integer x) {
    if (x == 0) return;
    outchan = x;
    list params =  llParseString2List(llGetStartString(), ["|"], []);
    float length = (float) (string) params[0];
    float diameter = (float) (string) params[1];
    integer strength = (integer) (string) params[2];
    integer weight = (integer) (string) params[3];
    offset = (vector)(string)params[4];
    lrot = (rotation)(string)params[5];
    update_offset = FALSE;
    lifter = NULL_KEY;
    animation = "";
    
    llSetScale(<diameter, diameter, length>);
    origin = llGetPos();
    channel = (integer)("0x"+llGetSubString((string) llGetLinkKey(LINK_THIS), -4, -1));
    llListen(channel, "", NULL_KEY, "");
    llSetTimerEvent(0.75);
  }

  timer() {
    llSetTimerEvent(0);
    llSay(outchan, "bar rezzed");
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    list message = llParseString2List(msg, ["|"],[]);
    switch((string) message[0]) {
    case "move" : {
      update_offset = TRUE;
      vector v = (vector)(string)message[1];
      offset += v;
      llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, llGetLocalPos() + v]);
      break;
    }
    case "attach": {
      integer i;
      integer linkCount = llGetNumberOfPrims();
      animation = (string) message[1];
      // Get and store all child prim local positions and rotations
      for (i=2; i<=linkCount; i++)  {
	list x = llGetLinkPrimitiveParams(i,
					  [PRIM_POS_LOCAL,
					   PRIM_ROT_LOCAL,
					   PRIM_SIZE]);
	//llOwnerSay("a "+(string) x[1]);
	data += [i] + x;
      }
      llRequestExperiencePermissions((key) (string) message[1], "");
      break;
    }
    case "detach": {
      if (update_offset && lifter != NULL_KEY) {
	llUpdateKeyValue((string) lifter + "+" + animation + "+BAR", (string) offset,
			 FALSE, "");
      }
      llDetachFromAvatar();
      break;
    }
    case "die": {
      if (llGetAttached()) {
	if (update_offset && lifter != NULL_KEY) {
	  die_key = llUpdateKeyValue((string) lifter + "+" + animation + "+BAR", (string) offset,
				     FALSE, "");
	} else {
	  llDetachFromAvatar();	
	}
      }
      llDie();
      break;
    }
    default: break;
    }
  }
  experience_permissions(key avi) {
    lifter = avi;
    die_key = NULL_KEY;
    data_key = llReadKeyValue((string) lifter + "+" + animation + "+BAR");
  }
  
  dataserver(key k, string data) {
    switch(k) {
    case data_key: {
      data_key = NULL_KEY;
      if (llGetSubString(data,0,0) == "1") {
	offset = (vector) llGetSubString(data,2,-1);
      }
      llAttachToAvatarTemp(ATTACH_RHAND);
      break;
    }
    case die_key: {
      llDetachFromAvatar();
      break;
    }
    default: break;
    }
  }
  
  attach(key id) {
    if (id) {
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_ROT_LOCAL, lrot,
				    PRIM_POS_LOCAL, llGetLocalPos() + offset]);
      integer i;
      integer count = llGetListLength(data);
      
      // Re-apply the stored local positions and rotations to the child prims
      for (i=0; i<count; i+=4)  {
	integer linkNum = (integer) data[i];
	vector localPos = (vector) data[i+1];
	rotation localRot = (rotation)data[i+2];
	vector size = (vector) data[i+3];
	//llOwnerSay((string) llRot2Euler(localRot));
	llSetLinkPrimitiveParamsFast(linkNum,
				     [PRIM_POS_LOCAL, localPos,
				      PRIM_ROT_LOCAL, localRot,
				      PRIM_SIZE, size]);
      }
      llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_NONE, 0]);
      llSay(channel,"attached");
    }
  }
}
