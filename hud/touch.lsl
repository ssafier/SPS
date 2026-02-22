#ifndef debug
#define debug(x)
#endif

key avi;
default {
  touch_start(integer x)  {
    string link = (string)llDetectedLinkNumber(0);
    string face = (string)llDetectedTouchFace(0);
    avi = (key) llDetectedKey(0);
    debug(link);
    debug(face);
    debug(x);
    llMessageLinked(LINK_SET, 0, "contact+" + (string) avi,
		    "fw_touchquery:" + link + ":" + face);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    debug("reply "+msg);
    debug("reply "+(string)xyzzy);
    if ((string) xyzzy == "fw_touchreply") {
      llMessageLinked(LINK_SET, 998, "|"+msg, avi);
    }
  }
}
