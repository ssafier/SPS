#include "controlstack.h"
#include "evolve/sps.h"

#ifndef debug
#define debug(x)
#endif

key request;
key agent;

GLOBAL_DATA;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != saveLifterStats) return;
    debug(msg);
    GET_CONTROL_GLOBAL;
    string method;
    POP(method);
    string json;
    POP(json);
    agent = xyzzy;
    //llOwnerSay("requested");
    debug(SERVER+"/sps/"+method);
    request = llHTTPRequest(SERVER+"/sps/"+method,
			    [HTTP_MIMETYPE, "application/json",
			     HTTP_METHOD, "POST"],
			    json);
  }
  http_response(key r, integer status, list meta, string body) {
    if (r != request) return;
    debug((string) status + body);
    if (status != 200) {
      PUSH(status);
      PUSH("server");
      return;
    } else {
      if (llJsonGetValue(body,["status"]) == "error") {
	PUSH(llJsonGetValue(body, ["error"]));
	PUSH("error");
      } else {
	PUSH(llJsonGetValue(body,["status"]));
      }
    }
    key xyzzy = agent;
    NEXT_STATE;
  }
}
