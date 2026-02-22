#include "controlstack.h"
#include "mg/messages.h"

#ifndef debug
#define debug(x)
#endif

#define Forward "=>"
#define Backward "<="

#define ActiveTime 20

integer menuChannel;

integer handle = 0;

integer next;
string rest;
string data;
key agent;
string text;

list menu_items = [];
integer menuIter = 0;

// Simple Multipage Menu  --  Rolig Loon --  August 2013

// The Menu routine in this script will parse your input list (gNames) into menu pages
//    of 12 buttons each, including a forward button and a back button, as appropriate.
//    It generates a page's buttons on demand, so that the list of button labels is
//    never more than 12 items long.
//    It does NOT trim potential menu items to fit the 25-character limit (or the 
//    12-character display limit), nor does it sort buttons or do other fancy things
//    that you are free to add for yourself.


Menu(string text, key agent) {
  integer Last;
  list Buttons;
  integer All = llGetListLength(menu_items);
  if(menuIter >= 9) {  //This is NOT the first menu page
    Buttons += Backward;
      if((All - menuIter) > 11)  {// This is not the last page
	Buttons += Forward;
      } else {    // This IS the last page
	Last = TRUE;
      }            
  } else if (All > menuIter+9) { // This IS the first page
    if((All - menuIter) > 11)  { // There are more pages to follow
      Buttons += Forward;
    } else {    // This IS the last page
      Last = TRUE;
    }            
  } else {    // This is the only menu page
    Last = TRUE;
  }
  if (All > 0) {
    integer b;
    integer len = llGetListLength(Buttons);
    // This bizarre test does the important work ......        
    for(b = menuIter + len + Last - 1 ; (len < 12)&&(b < All); ++b) {
      Buttons = Buttons + [(string)menu_items[b]];
      len = llGetListLength(Buttons);
    }
  }
  llDialog(agent, text, Buttons, menuChannel);
}

default {
  state_entry() {
    menuIter=0; 
    menuChannel = (integer) ("0x"+llGetSubString((string)llGetKey(),-4,-1));
    handle = -1;
    agent = NULL_KEY;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == doMenu) {
      string seq;
      string n;
      GET_CONTROL_GLOBAL;
      list line;
      text = "";

      llSetTimerEvent(0);

      POP(text);
      POPlist(line, "+");
      menuIter=0; 
      menu_items= line; 
      if (handle == -1) {
	handle = llListen(menuChannel, "", agent = xyzzy, "");
      } else if (agent != xyzzy) {
	llListenRemove(handle);
	handle = llListen(menuChannel, "", agent = xyzzy, "");
      }
      llListenControl(handle, TRUE);
      Menu(text, agent);
      llSetTimerEvent(ActiveTime);
    }
  }

  
  listen(integer channel, string name, key  id,  string msg) {
    debug(msg);
    switch (msg) {
    case Forward: {
      llSetTimerEvent(0);
      menuIter += 10;
      Menu(text, agent);
      llSetTimerEvent(ActiveTime);
      break;
    }
    case Backward: {
      llSetTimerEvent(0);
      menuIter -= 10;
      Menu(text, agent);
      llSetTimerEvent(ActiveTime);
      break;
    }
    default: {
      llSetTimerEvent(0);
      llListenControl(handle, FALSE);
      key xyzzy = agent;
      PUSH(msg);
      debug(next);
      NEXT_STATE;
    }
    }
  }
  timer() {
    llSetTimerEvent(0);
    llListenControl(handle, FALSE);
    PUSH("[time out]");
    key xyzzy = agent;
    NEXT_STATE;
  }
}

