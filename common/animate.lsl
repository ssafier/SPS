#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

key current_avatar = NULL_KEY;
integer flags;
string animation;
string cached_animation;

// -------------------------
stopAllAnims(key avi) {
  list anims = llGetAnimationList(avi);
  integer len = llGetListLength(anims);
  while(len) {
    --len;
    llStopAnimation((key) anims[len]);
  }
}

// ---------------------
reset() {
  flags = 0;
  animation = "";
  current_avatar = NULL_KEY;
  cached_animation = "stand";
}

// ----------------------
animate(key agent) {
  if (flags & afStopAll) {
    stopAllAnims(agent);
  }
  integer replace = (flags & afReplace) != 0;
#ifdef USE_Dev_FLEXES
  integer index = llSubStringIndex(animation,"~");
  if (index != -1) {
    string flexes = llGetSubString(animation, index+1, -1);
    animation = llGetSubString(animation, 0, index -1);
    llMessageLinked(LINK_THIS, devMuscleFlex, ((string) (flags & afLoop)) + "|" + flexes, agent);
  }
#endif
  if (replace) llStopAnimation(cached_animation);
  if ((flags & afCache) != 0) {
    if (!replace && (animation != cached_animation)) llStopAnimation(cached_animation);
    llStartAnimation(cached_animation = animation);
  } else {
    llStartAnimation(animation);
  }
}

// ----------------------
default {
  state_entry() {
    reset();
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == resetAnimationState) {
      reset();
      return;
    }
    if (chan != doAnimate) return;
    integer index = llSubStringIndex(msg,"|");
    flags = (integer) llGetSubString(msg,0, index-1);
    animation = llGetSubString(msg,index+1,-1);
    animate(xyzzy);
    if (xyzzy == current_avatar) {
    } else {
      debug("here "+(string)xyzzy);
      llRequestExperiencePermissions(xyzzy, "");
    }
  }

  experience_permissions(key avi) {
    animate(current_avatar = avi);
  }
}
