#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

integer active;
float speed_inc;
float resist_inc;
key runner;

default {
  state_entry() { active = FALSE; }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != TextButton &&
	chan != SpeedTouch &&
	chan != ResistTouch &&
	chan != TreadmillMenu &&
	chan != activateButtons &&
	chan != deactivateButtons) {
      return;
    }

    switch (chan) {
    case activateButtons: {
      debug("activate");
      resist_inc = 1;
      speed_inc = 0.1;
      runner = xyzzy;
      llMessageLinked(LINK_SET, setSpeedText, "Increase speed\n"+(string) speed_inc + "kM/H", xyzzy);
      llMessageLinked(LINK_SET, setResistText, "Increment resistance", xyzzy);
      active = TRUE;
      break;
    }
    case deactivateButtons: {
      debug("deactivate");
      runner = NULL_KEY;
      llMessageLinked(LINK_SET, setSpeedText, "", xyzzy);
      llMessageLinked(LINK_SET, setResistText, "", xyzzy);
      active = FALSE;
      break;
    }
    default: {
      if (active == FALSE) return;
      break;
    }
    }
    if (xyzzy != runner || chan == activateButtons || chan == deactivateButtons) return;
    debug("testing");
    switch (chan) {
    case TreadmillMenu: {
      string cmd = llGetSubString(msg,1,-1);
      switch(cmd) {
      case "[Stand]": {
	llUnSit(xyzzy);
	break;
      }
      case "Speed": {
	string buttons;
	if (speed_inc < 0) {
	  buttons = "[Stand]+Inc Speed+";
	  if (speed_inc < -0.1) {
	    buttons = buttons + "-0.1kM/H";
	  } else {
	    buttons = buttons + "-1kM/H";
	  }
	} else {
	  buttons = "[Stand]+Dec Speed+";
	  if (speed_inc > 0.1) {
	    buttons = buttons + "0.1kM/H";
	  } else {
	    buttons = buttons + "1kM/H";
	  }
	}
	llMessageLinked(LINK_THIS,
			doMenu,
			sTreadmillMenu+"|Change speed settings|"+buttons,
			xyzzy);
	break;
      }
      case "Dec Speed": {
	if (speed_inc > 0) speed_inc = -speed_inc;
	llMessageLinked(LINK_SET, setResistText, "Decrease speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "Inc Speed": {
	if (speed_inc < 0) speed_inc = -speed_inc;
	llMessageLinked(LINK_SET, setResistText, "Increase speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "-0.1kM/H": {
	speed_inc = -0.1;
	llMessageLinked(LINK_SET, setResistText, "Decrease speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "-1kM/H": {
	speed_inc = -1;	
	llMessageLinked(LINK_SET, setResistText, "Decrease speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "0.1kM/H": {
	speed_inc = 0.1;
	llMessageLinked(LINK_SET, setResistText, "Increase speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "1kM/H": {
	speed_inc = 1;
	llMessageLinked(LINK_SET, setResistText, "Increase speed\n"+llGetSubString((string) (speed_inc * 1000), 0, 2) + "kM/H", xyzzy);
	break;
      }
      case "Resistance": {
	string buttons;
	if (resist_inc < 0) {
	  buttons = "[Stand]+Inc Resist+";
	} else {
	  buttons = "[Stand]+Dec Resist+";
	}
	llMessageLinked(LINK_THIS,
			doMenu,
			sTreadmillMenu+"|Change resistance settings|"+buttons,
			xyzzy);
	break;
      }
      case "Inc Resist": {
	if (resist_inc < 0) resist_inc = -resist_inc;
	llMessageLinked(LINK_SET, setResistText, "Increment resistance", xyzzy);
	break;
      }
      case "Dec Resist": {
	if (resist_inc > 0) resist_inc = -resist_inc;
	llMessageLinked(LINK_SET, setResistText, "Decrease resistance", xyzzy);
	break;
      }
      default: break;
      }

      break;
    }
    case TextButton: {
      integer index = llSubStringIndex(msg, ":");
      switch(llGetSubString(msg, 0, index - 1)) {
      case "Three": {
	llMessageLinked(LINK_SET, SetSpeed, "3000", NULL_KEY);
	break;
      }
      case "Six": {
	llMessageLinked(LINK_SET, SetSpeed, "6000", NULL_KEY);
	break;
      }
      case "Nine": {
	llMessageLinked(LINK_SET, SetSpeed, "9000", NULL_KEY);
	break;
      }
      case "Twelve": {
	llMessageLinked(LINK_SET, SetSpeed, "12000", NULL_KEY);
	break;
      }
      case "Fifteen": {
	llMessageLinked(LINK_SET, SetSpeed, "15000", NULL_KEY);
	break;
      }
      case "Menu": {
	llMessageLinked(LINK_THIS, doMenu, sTreadmillMenu + "|SPS Treadmill|Speed+Resistance+[Stand]", xyzzy);
	break;
      }
      default: {
	break;
      }
      }

      break;
    }
    case SpeedTouch: {
      if (speed_inc < 0) {
	llMessageLinked(LINK_THIS, SpeedDown, (string)(speed_inc * -1000), xyzzy);
      } else {
	llMessageLinked(LINK_THIS, SpeedUp, (string)(speed_inc * 1000), xyzzy);
      }
      break;
    }
    case ResistTouch: {
      if (resist_inc < 0) {
	llMessageLinked(LINK_THIS, ResistDown, (string)(-resist_inc), xyzzy);
      } else {
	llMessageLinked(LINK_THIS, ResistUp, (string)(resist_inc), xyzzy);
      }
      break;
    }
    default: break;
    }
  }
}
