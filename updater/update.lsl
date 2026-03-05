#include "include/controlstack.h"
#include "include/sps.h"
#include "include/update.h"

#ifndef debug
#define debug(x)
#endif

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != updateEquipment) return;
    GET_CONTROL;
    NEXT_STATE;
  }
}
