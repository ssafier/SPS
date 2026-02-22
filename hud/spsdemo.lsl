#define UpdateStatus 100

integer arms;
integer legs;
integer chest;
integer core;
integer back;
integer arms_status;
integer legs_status;
integer chest_status;
integer core_status;
integer back_status;

default {
  state_entry() {
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    while(currentLinkNumber <= objectPrimCount) {
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME, PRIM_DESC]);
      string name = (string) params[0];
      switch (name) {
      case "arms": {
	arms = currentLinkNumber;
	break;
      }
      case "legs": {
	legs = currentLinkNumber;
	break;
      }
      case "core": {
	core = currentLinkNumber;
	break;
      }
      case "back": {
	back = currentLinkNumber;
	break;
      }
      case "chest": {
	 chest = currentLinkNumber;
	break;
      }
      case "arms status": {
	arms_status = currentLinkNumber;
	break;
      }
      case "chest status": {
	chest_status = currentLinkNumber;
	break;
      }
      case "legs status": {
	legs_status = currentLinkNumber;
	break;
      }
      case "back status": {
	back_status = currentLinkNumber;
	break;
      }
      case "core status": {
	core_status = currentLinkNumber;
	break;
      }
      default: break;
      }
      currentLinkNumber++;
    }      
  }

  attach(key id) {
    if (id) {
      llResetOtherScript("[SML] DevKit_v1.0");
      llSleep(0.2);
      llMessageLinked(LINK_THIS, 90060, "1", id);
      llMessageLinked(LINK_THIS, 55001,"SML", NULL_KEY); 
    }
  }
    
  link_message(integer from, integer chan, string msg, key xyzzy) {
    string cmd = (string) xyzzy;
    switch (cmd) {
    case "fw_ready": {
      llMessageLinked(from, 0, "", "fw_addbox : Body : PowerUI : 0, 0, 16, 5 : a=left;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ArmsStr : PowerUI : 6, 0, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ChestStr : PowerUI : 6, 1, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : CoreStr : PowerUI : 6, 2, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : BackStr : PowerUI : 6, 3, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : LegsStr : PowerUI : 6, 4, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : BackPct : PowerUI : 14, 3, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : LegsPct : PowerUI : 14, 4, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : TotalStr : PowerUI : 6, 5, 7, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ArmsPct : PowerUI : 14, 0, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : ChestPct : PowerUI : 14, 1, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(from, 0, "", "fw_addbox : CorePct : PowerUI : 14, 2, 2, 1 : a=right;c=white;w=none");
      llMessageLinked(LINK_THIS, 0, "Arms\nChest\nCore\nBack\nLegs", "fw_data: Body");	    
      break;
    }
    default: {
      switch (chan) {
      case 55002: {
	/////////////////////////////////////////////////////////
	// link_message second parameter number is 55002 for receive.
	// have to parse sMsg, you don't need to modify this area
	integer strength = 0;
	integer stamina = 0;
	integer level = 0;
	integer hud_version = 0;
	integer i = 0;
	list lTemp = llParseString2List(msg,["|"],[]);
	for(i=0;i<llGetListLength(lTemp);i++) {
	  list lTemp2 = llParseString2List(llList2String(lTemp, i), [":"], [] );
	  integer _val = (integer) (string)lTemp2[1];
	  switch((string)lTemp2[0]) {
	  case  "STRENGTH": {
	    strength = _val;
	    break;
	  }
	  case "STAMINA": {
	    stamina = _val;
	    break;
	  }
	  case "LEVEL": {
	    level = _val;
	    break;
	  }
	  case "VERSION": {
	    hud_version = _val;
	    break;
	  }
	  default: break;
	  }
	}
	float arms2 = ((float) strength) * 0.05;
	float core2 =  ((float) strength) * 0.10;
	float legs2 =  ((float) strength) * 0.40;
	float back2 =  ((float) strength) * 0.25;
	float chest2 =  ((float) strength) * 0.20;
	llMessageLinked(LINK_THIS, 0, (string)((integer)arms2), "fw_data:ArmsStr");
	llMessageLinked(LINK_THIS, 0, (string)((integer)legs2), "fw_data:LegsStr");
	llMessageLinked(LINK_THIS, 0, (string)((integer)core2), "fw_data:CoreStr");
	llMessageLinked(LINK_THIS, 0, (string)((integer)back2), "fw_data:BackStr");
	llMessageLinked(LINK_THIS, 0, (string)((integer)chest2), "fw_data:ChestStr");
	llMessageLinked(arms_status, UpdateStatus,(string)((arms2 - (integer) arms2) * 100.0),NULL_KEY);
	llMessageLinked(legs_status, UpdateStatus,(string)((legs2 - (integer) legs2) * 100.0),NULL_KEY);      
	llMessageLinked(core_status, UpdateStatus,(string)((core2 - (integer) core2) * 100.0),NULL_KEY);      
	llMessageLinked(chest_status, UpdateStatus,(string)((chest2 - (integer) chest2) * 100.0),NULL_KEY);      
	llMessageLinked(back_status, UpdateStatus,(string)((back2 - (integer) back2) * 100.0),NULL_KEY);
	llMessageLinked(LINK_THIS, 0, (string)(((integer)arms2) +((integer)legs2) +((integer)core2) +((integer)back2) +((integer)chest2)), "fw_data: TotalStr");
	llMessageLinked(LINK_THIS, 0, "10", "fw_data:ArmsPct");
	llMessageLinked(LINK_THIS, 0, "50", "fw_data:LegsPct");
	llMessageLinked(LINK_THIS, 0, "10", "fw_data:BackPct");
	llMessageLinked(LINK_THIS, 0, "0", "fw_data:ChestPct");
	llMessageLinked(LINK_THIS, 0, "5", "fw_data:CorePct");
	llSetLinkPrimitiveParamsFast(arms,[PRIM_COLOR, ALL_SIDES, <1,0.647,0>,1]);
	llSetLinkPrimitiveParamsFast(legs,[PRIM_COLOR, ALL_SIDES, <1,0,0>,1]);	
	llSetLinkPrimitiveParamsFast(back,[PRIM_COLOR, ALL_SIDES, <1,0.647,0>,1]);
	llSetLinkPrimitiveParamsFast(core,[PRIM_COLOR, ALL_SIDES, <1,1,0>,1]);
	break;
      }
      default: break;
      }
      break;
    }
    }
    }
}
