#define LENGTH 2.5
integer channel;
integer handle;
vector origin;
vector offset;
rotation lrot;

list data;
integer outchan;

rotation RotBetween(rotation x, rotation y) {
  vector a = llVecNorm(llRot2Euler(x));
  vector b = llVecNorm(llRot2Euler(y));
  float aabb = llSqrt((a * a) * (b * b)); // product of the lengths of the arguments
  if (aabb) {
    float ab = (a * b) / aabb; // normalized dotproduct of the arguments (cosine)
    vector c = <(a.y * b.z - a.z * b.y) / aabb,
		(a.z * b.x - a.x * b.z) / aabb,
		(a.x * b.y - a.y * b.x) / aabb >; // normalized crossproduct of the arguments
    float cc = c * c; // squared length of the normalized crossproduct (sine)
    if (cc) { // test if the arguments are not (anti)parallel
      float s;
      if (ab > -0.707107)
	s = 1 + ab; // use the cosine to adjust the s-element
      else 
	s = cc / (1 + llSqrt(1 - cc)); // use the sine to adjust the s-element
      float m = llSqrt(cc + s * s); // the magnitude of the quaternion
      return <c.x / m, c.y / m, c.z / m, s / m>; // return the normalized quaternion
    }
    if (ab > 0) return ZERO_ROTATION; // the arguments are parallel, or anti-parallel if not true:
    float m = llSqrt(a.x * a.x + a.y * a.y); // the length of one argument projected on the XY-plane
    if (m) return <a.y / m, -a.x / m, 0, 0>; // return a rotation with the axis in the XY-plane
    return <1, 0, 0, 0>; // the arguments are parallel to the Z-axis, rotate around the X-axis
  }
  return ZERO_ROTATION; // the arguments are too small, return zero rotation
}

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
    case "attach": {
      integer i;
      integer linkCount = llGetNumberOfPrims();

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
      llDetachFromAvatar();
      break;
    }
    case "die": {
      if (llGetAttached()) llDetachFromAvatar();
      llDie();
      break;
    }
    default: break;
    }
  }
  experience_permissions(key lifter) {
    llAttachToAvatarTemp(ATTACH_RHAND);
  }
  attach(key id) {
    if (id) {
      integer i;
      integer count = llGetListLength(data);
      vector up = <1,0,0>;
      vector left = <0,0,1>;
      vector fwd = left % up;
      rotation wrist = <0,0,0.0698,0.9976>;
      rotation target = llAxes2Rot(fwd, left, up);
      rotation local =  llAxes2Rot(llRot2Fwd(wrist), llRot2Left(wrist), llRot2Up(wrist));
      rotation angle = RotBetween(local, target);

      llOwnerSay((string) (llRot2Euler(angle)*RAD_TO_DEG));
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_ROT_LOCAL, target / wrist, //lrot
				    PRIM_POS_LOCAL, llGetLocalPos() + offset]);

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
