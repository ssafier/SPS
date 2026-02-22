default {
  state_entry() {
    llSetClickAction(CLICK_ACTION_TOUCH);
  }
  //<436,548,0><22,15,0>
  //<436,562,0><22,15,0>
  //<422,548,0><14,29,0>

  touch_start(integer x) {
    vector point = llDetectedTouchUV(0);

#ifdef REPORT
    llSay(0,(string)llDetectedTouchFace(0));
    llSay(0,(string)point);
#endif
    if (point.x < 0.422 || point.x > 0.448) return;
    if (point.y < 0.548 || point.y > 0.577) return;
    if (point.x < 0.436) {
      llSay(0, "BUY");
    } else  if (point.y < 0.562) {
      llSay(0, "Previous");
    } else {
      llSay(0, "Next");
    }
  }
}

