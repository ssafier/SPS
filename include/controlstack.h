// A unified frameword for controling the invocation of scripts and passing data.
//
// Problem: the communication queue behind LSL is non deterministic.  Events may be
//   triggered as A then B or B then A.  This leads to race conditions.
// Problem: in-object and interobject communications have different APIs.  Complex
//   systems need to interact with other objects either worn or in the environment.
//
//  This library unifies an API around the second integer parameter of llMessageLinked.
//  Control is directed by giving each state of a complex system a unique integer.
//  States are stringed together, where each state acts on a set of expected parameters
// and creates a set of outputs that are passed to the next state.  In other words, each state
// can be thought of as a function that takes inputs off a stack and puts outputs on a stack,
// or a microservice that when promised a set of inputs will produce a set of outputs.
//
//  Both listeners and linked messages have a message string parameter.  This message is
// used to both specify control and pass data as a stack between states.
//      The vericle bar (|) is used to separate control from data and each data element in
//         the stack. (i.e. state1+state2+state3|data1|data2|...)
//       Control is a sequence of integers separated by plus signs (+).  No state may
//         have the value zero (0).
//   example message:  "10+12+11|data 1||data 3"
//
//  Signatures:
//    link_message(integer from (unused), integer chan, string msg, key xyzzy)
//    listen(integer channel2listen, string name (unused), key xyzzy (unused), string msg)

// data.  this data may be local or gloal, as used below
//   n -- temporary next state
//   data -- data portion of the message
//   rest -- control sequence AFTER the next is removed
//   seq -- control sequence (next not removed)
//   next -- the next state

#define GLOBAL_DATA				\
    string n; \
    string data = ""; \
    string rest = ""; \
    string seq = ""; \
    integer next

// Assignment of variables

// LOCAL
#define GET_CONTROL  GLOBAL_DATA; GET_CONTROL_GLOBAL

// for listen
//  the listen channel is repurposed to be the variable chan consisten with link_message

#define LISTEN_CONTROL  GLOBAL_DATA;  \
  integer index = llSubStringIndex(msg,"|");				\
  if (index != -1) {							\
    if (index != 0) seq = n = llGetSubString(msg, 0, index - 1); else n = "0"; \
    if (index + 1 < llStringLength(msg)) data = llGetSubString(msg, index + 1, -1); \
  } else {								\
    n = msg;								\
    data = "";								\
  }									\
  index = llSubStringIndex(n, "+");					\
  if (index != -1) {							\
    rest = llGetSubString(n, index + 1, -1);				\
    n = llGetSubString(n, 0, index - 1);				\
  } else {								\
    rest = "";								\
  }									\
  if (n != "") {							\
    chan = (integer) n;							\
    index = llSubStringIndex(rest, "+");				\
    if (index != -1) {							\
      rest = llGetSubString(n, index + 1, -1);				\
      next = (integer) llGetSubString(n, 0, index - 1);			\
    } else {								\
      next = (integer) rest;						\
      rest = "";							\
    }									\
  } else {								\
    chan = 0;								\
    next = 0;								\
  }

// link_message (GLOBAL)
#define GET_CONTROL_GLOBAL \
  integer index = llSubStringIndex(msg,"|");				\
  if (index != -1) {							\
      if (index != 0) seq = n = llGetSubString(msg, 0, index - 1); else n = "0"; \
      if (index + 1 < llStringLength(msg)) data = llGetSubString(msg, index + 1, -1); \
    } else { \
      n = msg; \
      data = ""; \
    } \
    index = llSubStringIndex(n, "+"); \
    if (index != -1) { \
      rest = llGetSubString(n, index + 1, -1); \
      n = llGetSubString(n, 0, index - 1); \
    } else { \
      rest = ""; \
    } \
    if (n != "") next = (integer) n; else next = 0;

// Advance to next state, passing the data 

#ifndef LinkType
#define LinkType LINK_THIS
#endif
#define NEXT_STATE  if (next  != 0)  llMessageLinked(LinkType, next, rest + "|" + data,  xyzzy);


// Remove and save first element off the top of the stack
#define POP(x) \
      index = llSubStringIndex(data,"|"); \
      if (index > 0) { \
	x = llGetSubString(data,0, index - 1); \
	if ((index + 1) < llStringLength(data)) data = llGetSubString(data,index+1,-1);  else data=""; \
      } else { \
        if (index == 0)  { x = ""; data = llGetSubString(data,1,-1); } else { \
	  x = data;							\
	  data = ""; }							\
      }					    

// check if there is an element on the stack.  Take it if it exists or return the default.
#define POP_DEFAULT(x,y)			  \
      index = llSubStringIndex(data,"|"); \
      if (index > 0) { \
	x = llGetSubString(data,0, index - 1); \
	if ((index + 1) < llStringLength(data)) data = llGetSubString(data,index+1,-1);  else data=""; \
      } else { \
        if (index == 0)  { x = y; data = llGetSubString(data,1,-1); } else { \
	if (data != "") {\
	  x = data;							\
	  data = ""; } else { x = y;	}				\
	}}					    

// Take the first element off the stack and translate it into a list, assigning it to the variable
// y
#define POPlist(x, y)			  \
      index = llSubStringIndex(data,"|"); \
      if (index +1 >= llStringLength(data)) data = llGetSubString(data,0,-2); \
      if (index > 0 && (index + 1) < llStringLength(data)) { \
	x = llParseStringKeepNulls(llGetSubString(data,0, index - 1),  [y], []); \
	data = llGetSubString(data,index+1,-1); \
      } else { \
	if (index == 0)  { x = []; data = llGetSubString(data,1,-1); } else{ \
	  x = llParseStringKeepNulls(data, ["+"], []);			\
	  data = ""; }							\
      }					    

// add an element to the front of the stack.  checks to make sure stack is not empty
#define PUSH(x)  if (data == "") data = (string) (x); else data = (string) (x) + "|" + data;
// add an element to the front of the stack.  the stack is known to not be empty
#define PUSHsafe(x)  data = (string) (x) + "|" + data;

// non destructive POP -- gets the first element without removing it from the stack
#define PEEK(x) \
      index = llSubStringIndex(data,"|"); \
      if (index != -1) {\
	x = llGetSubString(data,0, index - 1);		       \
      } else { \
	x = data; \
      }					    

// CONTROL operators

// push a new state to go to after next
#define PUSH_CNTRL(x) \
  if (seq != "") rest = "+" + seq; \
  seq = rest = (string) (x) + rest

// same as above but seq is known not to be empty
#define SAFE_PUSH_CNTRL(x) \
  seq = rest = (string) (x) + "+" + rest

// add a state after all the rest
#define APPEND_CNTRL(x) \
  if (rest != "") rest = rest + "+";	\
  if (seq != "") seq = seq + "+";	\
  seq = seq + (string) x; \
  rest = rest + (string) (x)

// same as above, but rest and seq are known not be be empty
#define SAFE_APPEND_CNTRL(x) \
  seq = seq + "+" + (string) x; \
  rest = rest + "+" +(string) (x)

// change the next state to visit
#define UPDATE_NEXT(n) \
  rest = seq; \
  next = (integer) (n)

// take a state from the control stack
#define POP_CNTRL() \
  seq = rest; \
  if (rest != "") { integer ind = llSubStringIndex(rest, "+"); \
    if (ind != -1) { \
      next = (integer) llGetSubString(rest, 0, ind - 1);	\
      rest = llGetSubString(rest, ind + 1, -1); \
    } else { next = (integer) rest; rest = ""; } } else next = 0;

// define a variable and pop the top of the data stack
#define POP_DEFINE(x) string x; POP(x)
