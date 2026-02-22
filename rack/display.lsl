#define SetLifter 1001
#define InUse 1001
#define ClearLifter 1002
#define ReadyForLifter 1008

#define COLOR <0.9,0.45,0>
#define READY_MSG "Touch to configure and workout.\nSPS HUD required."
default
{
  state_entry()
    {
      llSetText(READY_MSG,COLOR,1);
    }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case InUse: {
      llSetText("In use by "+msg, COLOR, 1);
      break;
    }
    case ClearLifter: {
      llSetText(READY_MSG, COLOR, 1);
      break;
    }
    case ReadyForLifter: {
      llSetText(READY_MSG, COLOR, 1);
      break;
    }
    default: break;
    }
  }
}
