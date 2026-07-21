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
float animation_scale;

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
    animation_scale = (float) params[4];
    if (animation_scale == 0) animation_scale = 1;
    offset = ZERO_VECTOR;
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
      // 1. Give the animation a moment to pose the avatar
      llSleep(0.5); 

      // 2. Get the avatar's bounding box size
      vector agent_size = llGetAgentSize(id);

      // 3. agent_size.y is the avatar's width (shoulder to shoulder).
      // We multiply this by your animation scale/tuning factor to get the slide distance.
      // Note: You may need to make animation_scale negative depending on which hand 
      // the bar is attached to, to slide it towards the body center.
      float slide_distance = agent_size.y * animation_scale;

      // 4. Enforce the 90-degree Y rotation so it lays horizontally across the hands
      rotation bar_local_rot = llEuler2Rot(<0.0, 90.0, 0.0> * DEG_TO_RAD);

      // 5. Because the bar is rotated 90 degrees around Y, its local Z-axis now points
      // left/right relative to the avatar's body. We map the slide distance to that Z-axis.
      vector slide_vector = <0.0, 0.0, slide_distance> * bar_local_rot;

      // 6. Start from a pure zero baseline so it never compounds across multiple sets
      vector base_grip_offset = ZERO_VECTOR; 
      vector final_local_pos = base_grip_offset + slide_vector; 

      // 7. Apply! 
      llSetLinkPrimitiveParamsFast(LINK_ROOT, [
					       PRIM_POS_LOCAL, final_local_pos, 
					       PRIM_ROT_LOCAL, bar_local_rot
					       ]);

      // Make sure the plates are where they should be
      integer i;
      integer count = llGetListLength(data);
      
      // Re-apply the stored local positions and rotations to the child prims
      for (i=0; i<count; i+=4)  {
	integer linkNum = (integer) data[i];
	vector localPos = (vector) data[i+1];
	rotation localRot = (rotation) data[i+2];
	vector size = (vector) data[i+3];
	//llOwnerSay((string) llRot2Euler(localRot));
	llSetLinkPrimitiveParamsFast(linkNum,
				     [PRIM_POS_LOCAL, localPos,
				      PRIM_ROT_LOCAL, localRot,
				      PRIM_SIZE, size,
				      PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_NONE, 0
				      ]);
      }
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_NONE, 0]);
      llSay(channel,"attached");
    }
  }
}
