#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

// Script to send an flex animationstring to a dev or muscle devness avatar

#define FLEX_CHANNEL 1000

// key|lpeak|ON3|rpeak|ON3|ltric|OFF|rtric|OFF|back|ON2|rpec|ON2|lpec|ON2|abs|OFF|trap|OFF|rthig|OFF|lthig|OFF|rcalf|OFF|lcalf|OFF|rhip|OFF|lhip|OFF|lhand|FIST|rhand|FIST

#define cOffString "|lpeak|OFF|rpeak|OFF|ltric|OFF|rtric|OFF|back|OFF|rpec|OFF|lpec|ON2|abs|OFF|trap|OFF|rthig|OFF|lthig|OFF|rcalf|OFF|lcalf|OFF|rhip|OFF|lhip|OFF|lhand|RELAX|rhand|RELAX"

list flex_order;
integer loopP;
list flex_encodings;
integer flex_index;
integer flex_length;
key dev_avatar;

string devFlexString(string encoding) {
  integer len = llStringLength(encoding);
  if (llStringLength(encoding) != 15) {
    debug(encoding + " is not 15");
    return cOffString;
  }
  integer i;
  string out = (string) dev_avatar;
  for (i = 0; i < 15; ++i) {
    string n = llGetSubString(encoding,i,i);
    if (((integer) n) == 0) {
      out = out + "|" + (string) flex_order[i] + "|OFF";
    } else {
      out = out + "|" + (string) flex_order[i]  + "|ON" + n;
    }
  }
  return out + "|rhand|FIST|lhand|FIST";
}

sendFlex(string flex, integer index) {
  integer t = llSubStringIndex(flex, ":");
  float time = 0;
  if (t != -1) {
    time = (float) llGetSubString(flex, t + 1, -1);
    flex = llGetSubString(flex, 0, t - 1);
  }
  ++flex_index;
  llRegionSayTo(dev_avatar, FLEX_CHANNEL, devFlexString(flex));
  llSetTimerEvent(time);
}

default {
  state_entry() {
    flex_order  = ["rpeak","lpeak","rtric","ltric","back","rpec","lpec","abs","trap","rthig","lthig","rcalf","lcalf","rhip","lhip","rhand","lhand" ];
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != devMuscleFlex) return;
    integer index = llSubStringIndex(msg, "|");
    loopP = (((integer) llGetSubString(msg,0,index-1)) != 0);
    flex_length = llGetListLength(flex_encodings = llParseString2List(llGetSubString(msg, index + 1, -1), ["+"], []));
    dev_avatar = xyzzy;
    sendFlex((string) flex_encodings[flex_index = 0], flex_index);
  }
 
 timer() {
    if (flex_index >= flex_length && loopP) flex_index = 0;
    sendFlex((string) flex_encodings[flex_index], flex_index);
  }
}
