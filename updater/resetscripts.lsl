default {
  state_entry() {
    integer i;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    for (i = 0; i < count; ++i) {
      string name = llGetInventoryName(INVENTORY_SCRIPT, i);
      llSay(0,name);
      if (name != UPDATER) {
	llSetScriptState(name,FALSE);
      }
    }
    llRemoveInventory(llGetScriptName());
  }
}
