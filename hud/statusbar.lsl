#define UpdateStatus 100
// The face on the prim we will apply the status bar effect to
#define TEXTURE_FACE 4 

#define FILL_TEXTURE "0d795605-ceb6-f2c5-c3eb-376868509947"
#define BACKGROUND_TEXTURE "7b26cb99-c629-fd7f-2301-1075369d0414"

float g_bar_value = 0.0;

// --- FUNCTIONS ---

// Function to update the bar's texture scale and offset based on a value (0-100).
update_bar(float value) {
    // Clamp the value between 0 and 100 to prevent errors
    if (value > 100.0) value = 100.0;
    if (value < 0.0) value = 0.0;

    float u_offset = 0.25-(((g_bar_value = value)/ 100.0)/2.0);
    list params = [
        // Set the horizontal texture scale and offset on the specified face
		   PRIM_TEXTURE, TEXTURE_FACE, FILL_TEXTURE, 
		   <0.5, 1.0, 0.0>,    // Scale: <U_scale, V_scale, Rotation>
		   <u_offset, 0.0, 0.0>,   // Offset: <U_offset, V_offset, Repeat>
		   0];
    // Apply the changes
    llSetLinkPrimitiveParamsFast(LINK_THIS, params);
}

// --- EVENTS ---
default {
    state_entry()  {
        // Apply the background texture to all faces for contrast
        llSetPrimitiveParams([
			      PRIM_TEXTURE, ALL_SIDES, BACKGROUND_TEXTURE, <1,1,0>, <1.0, 1.0, 0.0>, 0
        ]);
        // Initialize the bar to a starting value
        update_bar(g_bar_value = 0);
    }
    
    link_message(integer from, integer chan, string msg, key xyzzy) {
      if (chan != UpdateStatus) return;
      update_bar((float) msg);
    }
}
