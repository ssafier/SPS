#include "include/controlstack.h" // standardized way to pass data and script instantiation

#define NOTECARD_NAME ".menu"

#define doMenu 2
#define getLeaf 4
#define returnLeaf 5
#define MENU_FAIL 6
#define registerSequence 11
#define runSequence 12
#define stopSequence 13

#ifndef debug
#define debug(x)
#endif

#define LEAF_STRIDE 5
#define LEAF_NAME 0
#define LEAF_SITTER_1_POSITION 1
#define LEAF_SITTER_1_ROTATION 2
#define LEAF_SITTER_2_POSITION 3
#define LEAF_SITTER_2_ROTATION 4
list leaves;
integer leaf_count;

#define NODE_NAME 0
#define NODE_DESCRIPTION 2
#define NODE_LEN 1
#define NODE_NEXT 3
list nodes;
integer node_count;

list sequences;

key note_handle;
// ------------------------------------------
parse_leaf(list leaf) {
  vector v1;
  rotation r1 = ZERO_ROTATION;
  vector v2;
  rotation r2 = ZERO_ROTATION;
  list temp = llParseString2List((string) leaf[2], [">"], []);
  v1 = (vector)((string) temp[0] + ">");
  if (llGetListLength(temp) == 2)
    r1 = llEuler2Rot((vector)((string) temp[1] + ">")*DEG_TO_RAD);
  temp = llParseString2List((string) leaf[3], [">"], []);
  v2 = (vector)((string) temp[0] + ">");
  if (llGetListLength(temp) == 2) {
    debug((string)leaf[3] + " " + (string) llGetListLength(temp) + (string) temp[0] + " "
	  + (string) temp[1]);
    r2 = llEuler2Rot((vector)((string) temp[1] + ">")*DEG_TO_RAD);
  }
  debug("leaf "+ (string) leaf[1] + " " +(string) temp[1]+ (string)r2);
  leaves = leaves +  [(string)leaf[1], v1, r1, v2, r2];
  ++leaf_count;
}
// ------------------------------------------
string makeMenu(integer node, string rest, string data) {
  string r = (string)(integer)nodes[node+NODE_NEXT];
  list items = [];
  integer l = (integer) nodes[node + NODE_LEN] - 4;
  integer i;
  for(i = 0; i < l; ++i) {
    items = items + [(string) nodes[node + 4 + i]];
  }
  if (rest != "") r = r + "+" + rest;
  debug(r + "|" + (string)nodes[node+NODE_DESCRIPTION] + "|" +    llDumpList2String(items,"+") + "|" + data);
  return r + "|" + (string)nodes[node+NODE_DESCRIPTION] + "|" +
    llDumpList2String(items,"+") + "|" + data;
}
// ------------------------------------------
integer findLeaf(string s) {
  integer x = 0;
  while (x < leaf_count) {
    debug((string) leaves[((x * LEAF_STRIDE)+LEAF_NAME)] + " == " + s);
    if ((string) leaves[((x * LEAF_STRIDE)+LEAF_NAME)] == s) return x;
    ++x;
  }
  return -1;
}
// ------------------------------------------
parse_node(list node) {
  list menu = llList2List(node, 4, -1);
  integer len = llGetListLength(menu);
  debug("Menu "+llDumpList2String(menu,"|"));
  nodes = nodes + [(string)node[1], len + 4, (string)node[2], (integer)(string)node[3]] + menu;
  ++node_count;
}
// ------------------------------------------
integer findNode(string s) {
  integer x = 0;
  integer index = 0;
  while (x < node_count) {
    debug((string) nodes[index + NODE_NAME] + " == " + s);
    if ((string) nodes[index + NODE_NAME] == s) return index;
    ++x;
    index += (integer) nodes[index + NODE_LEN];
  }
  return -1;
}
// ------------------------------------------
default {
  state_entry()  {
    sequences = nodes = leaves = [];
    leaf_count = node_count = 0;
	  llSay(0,"Loading configuration.");
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }
    
  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF) {
	  list elements = llParseString2List(line,["|"],[]);
	  if (elements != []) {
	    switch(llToUpper((string) elements[0])) {
	    case "LEAF": {
	      parse_leaf(elements);
	      break;
	    }
	    case "ROOT": {
	      elements = ["ROOT", "<root node>"] + llList2List(elements, 1, -1);
	    }
	    case "NODE": {
	      parse_node(elements);
	      break;
	    }

	    case "SEQUENCE": {
	      sequences = sequences + [(string) elements[1]];
	      llMessageLinked(LINK_THIS,
			      registerSequence,
			      llDumpList2String(llList2List(elements,1,-1), "|"),
			      NULL_KEY);
	      break;
	    }
	    default: {
	      llOwnerSay("Cannot parse line "+line);
	      break;
	    }
	    }
	  }
	} else {  // EOF
	  llSay(0,"Configuration loaded.");
	  state serve_data;
	}
      }
    }
  }
}

state serve_data {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != getLeaf) return;
    GET_CONTROL;
    string val;
    POP(val);
    debug("config "+val);
    integer node = findNode(val);
    if (node != -1) {
      PUSH(val); // create a list of menus called on stack
      llMessageLinked(LINK_THIS, doMenu, makeMenu(node, seq, data), xyzzy);
      llSetTimerEvent(20);
      return;
    }
    llSetTimerEvent(0);
    node = findLeaf(val);
    if (node != -1) {
      string peek;
      PEEK(peek);
      if (peek != "SEQUENCE")
	llMessageLinked(LINK_THIS, stopSequence, "", NULL_KEY);
      node *= LEAF_STRIDE;
      list n = llList2List(leaves, node, node+LEAF_STRIDE-1);
      debug("leaf "+llDumpList2String(n,"|"));
      if (data == "") {
	data = llDumpList2String(n,"|");
      } else {
	data = llDumpList2String(n,"|") + "|" + data;
      }
    } else if (llListFindList(sequences, [val]) == -1)  {
      llMessageLinked(LINK_THIS, stopSequence, "", NULL_KEY);
      PUSH(val);
      PUSH("STRING");
    } else {
      debug("Running sequence "+val);
      PUSH(val);
      UPDATE_NEXT(runSequence);
    }
    debug(data);
    debug(rest);
    NEXT_STATE;
  }
  timer() {
    llMessageLinked(LINK_THIS, MENU_FAIL, "", NULL_KEY);
    llSetTimerEvent(0);
  }
  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) state default;
  }
}
