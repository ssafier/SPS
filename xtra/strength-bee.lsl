#define channel (integer)("0x"+llGetSubString((string) llGetKey(), -4, -1))
key lifter;
integer count;

default {
  on_rez(integer x) {
    if (x == 0) return;
    llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
    lifter = (key) llGetStartString();
    llRequestExperiencePermissions(lifter, "");
  }
  experience_permissions(key id) {
    count = 0;
    llAttachToAvatarTemp(ATTACH_RHAND);
  }
  attach(key id) {
    if (id) {
      llResetOtherScript("[SML] DevKit_v1.0");
      llSleep(0.2);
      llMessageLinked(LINK_THIS, 90060, "1", lifter);
      llMessageLinked(LINK_THIS, 55001,"SML", NULL_KEY); 
      llSetTimerEvent(5);
    }
  }
  experience_permissions_denied(key id, integer x) {
    llDie();
  }
  link_message(integer sender_num, integer num, string sMsg, key id) {
    if(num != 55002) return;
    llSetTimerEvent(0);
    debug(sMsg);
    llShout(channel, sMsg);
    state detach;
  }
  timer() {
    ++count;
    if (count > 4) llDie();
    llMessageLinked(LINK_THIS, 55001,"SML", NULL_KEY);
  }
}

state detach {
  state_entry() {
    llRequestExperiencePermissions(lifter, "");
  }
  experience_permissions(key id) { llDetachFromAvatar(); }
}
