#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

// Communication channels
integer SYSTEM_CHANNEL = -99000;
integer session_channel = 0;

key trainer = NULL_KEY;
key current_lifter = NULL_KEY; // Track who is using the machine

vector target = <0,0,0.3>;
vector offset = <0,0,0>;
rotation target_rot = ZERO_ROTATION;
float fAdjust = 0.0;

integer handle;
integer initialized = FALSE;

// ---------------------------------------

// Calculates the global position and tells the Animesh to move
updateAnimeshTarget(vector pos, rotation rot) {
    if (trainer == NULL_KEY) return;
    
    // 1. Calculate the intended local offset (matching your original sit target math)
    vector local_pos = pos + offset + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust);
    
    // 2. Translate to Region (Global) coordinates
    vector global_pos = llGetPos() + (local_pos * llGetRot());
    rotation global_rot = rot * llGetRot();
    
    // 3. Send the movement command to the Animesh on its secure channel
    llRegionSayTo(trainer, session_channel, "update_pos|" + (string)global_pos + "|" + (string)global_rot);
}

// ---------------------------------------

checkUpdateSitTarget(vector t, rotation r) {
    if (t != target || r != target_rot) {
        target = t;
        target_rot = r;
        updateAnimeshTarget(target, target_rot);
    }
}

// ---------------------------------------

default {
    state_entry() {
        target = <-0.05000, -0.25000, 1.30000>;
        // Open the system channel to listen for Animesh characters offering to spot
        handle = llListen(SYSTEM_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string msg) {
        list parts = llParseString2List(msg, ["|"], []);
        string command = llList2String(parts, 0);
        
        // Handshake Protocol from Animesh
        // Expected format: offer_service | lifter_uuid | animesh_uuid | role
        if (command == "offer_service" && channel == SYSTEM_CHANNEL) {
            key avatar_id  = (key)llList2String(parts, 1);
            key animesh_id = (key)llList2String(parts, 2);
            string role    = llList2String(parts, 3);
            
            // Only accept if the animesh is offering to spot the current lifter on this machine
            if (role == "spotter" && avatar_id == current_lifter && trainer == NULL_KEY) {
                trainer = animesh_id;
                
                // Generate secure channel
                session_channel = (integer)("0x" + llGetSubString((string)trainer, 0, 7));
                
                // Calculate initial global placement
                vector local_pos = target + offset + <0.0, 0.0, 0.4> - (llRot2Up(target_rot) * fAdjust);
                vector global_pos = llGetPos() + (local_pos * llGetRot());
                rotation global_rot = target_rot * llGetRot();
                
                // Send initial setup payload: setup | pos | rot | anim | session_chan
                string setup_msg = "setup|" + (string)global_pos + "|" + (string)global_rot + "|spotter_idle|" + (string)session_channel;
                llRegionSayTo(trainer, SYSTEM_CHANNEL, setup_msg);
                
                // Notify the rest of the linkset that a spotter has connected
                llMessageLinked(LINK_SET, 0, "trainer_seated", trainer);
            }
        }
    }

    link_message(integer sender, integer num, string msg, key id) {
        list parts = llParseString2List(msg, ["|"], []);
        string command = llList2String(parts, 0);
        
        // Track the current lifter so the Animesh knows it's targeting the right machine
        if (command == "lifter_seated") {
            current_lifter = id;
        }
        else if (command == "lifter_unseated") {
            current_lifter = NULL_KEY;
            if (trainer != NULL_KEY) {
                // Dismiss the Animesh if the lifter leaves
                llRegionSayTo(trainer, session_channel, "dismiss");
                trainer = NULL_KEY;
                session_channel = 0;
            }
        }
        // Handle manual spotter dismissal
        else if (command == "trainer_unseated" && trainer != NULL_KEY) {
            llRegionSayTo(trainer, session_channel, "dismiss");
            trainer = NULL_KEY;
            session_channel = 0;
        }
        // Handle dynamic positioning from the rack (e.g., as the barbell moves up and down)
        else if (command == "position") {
            vector p = (vector)llList2String(parts, 1);
            rotation r = (rotation)llList2String(parts, 2);
            checkUpdateSitTarget(p, r);
        }
    }
}
