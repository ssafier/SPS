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
// 1. Give the animation a moment to fully pose the avatar
        llSleep(0.5); 

        // 2. Define the target center (using the 'origin' variable from bar.lsl)
        vector target_center = origin; 

        // 3. Get the avatar's root position and rotation
        vector root_pos = llGetPos();
        rotation root_rot = llGetRot();

        // 4. Get the bar's local offset and rotation relative to the hand
        vector local_pos = llGetLocalPos();
        rotation local_rot = llGetLocalRot();

        // 5. Reconstruct the TRUE world position and rotation of the bar
	rotation new_local_rot = llEuler2Rot(<0.0, -90.0, 0.0> * DEG_TO_RAD);
	vector bar_world_pos = root_pos + (local_pos * root_rot);
        rotation bar_world_rot = new_local_rot * root_rot;

        // 6. Calculate the world difference vector
        vector diff = target_center - bar_world_pos;

        // 7. Get the world-space direction of the bar's Z-axis (its shaft)
        vector bar_shaft_axis = <0.0, 0.0, 1.0> * bar_world_rot;

        // 8. Dot product: How far to slide along the bar's shaft to center it
        float slide_distance = diff * bar_shaft_axis * animation_scale;

        // 9. Apply the correction strictly to the local Z-axis
	vector slide_vector = <0.0, 0.0, slide_distance> * new_local_rot;
        local_pos -= slide_vector;

        llSetLinkPrimitiveParamsFast(LINK_ROOT,
				     [PRIM_POS_LOCAL, local_pos,
				      PRIM_ROT_LOCAL, new_local_rot]);
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
				      PRIM_SIZE, size]);
      }
      llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_NONE, 0]);
      llSay(channel,"attached");
    }
  }
}
