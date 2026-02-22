// The face on the prim we will apply the status bar effect to
integer TEXTURE_FACE = 4; 

// Placeholder UUIDs for demonstration. REPLACE THESE with your own textures.
// A solid, bright color texture for the 'filled' portion of the bar.
string FILL_TEXTURE = "0d795605-ceb6-f2c5-c3eb-376868509947";
// A dark/empty texture for the background (optional, but recommended).
string BACKGROUND_TEXTURE = "7b26cb99-c629-fd7f-2301-1075369d0414";

// --- STATE VARIABLES ---
// Global variable to hold the current bar value (0.0 to 100.0)
float g_bar_value = 0.0;

// --- FUNCTIONS ---

// Function to update the bar's texture scale and offset based on a value (0-100).
update_bar(float value) {
    // Clamp the value between 0 and 100 to prevent errors
    if (value > 100.0) value = 100.0;
    if (value < 0.0) value = 0.0;

    g_bar_value = value;

    // 1. Calculate the new U (Horizontal) scale
    // 50% value = 0.5 U scale; 100% value = 1.0 U scale
    float u_scale = g_bar_value / 100.0;
    
    // 2. Calculate the U (Horizontal) offset to anchor the bar to the left edge.
    // The texture system centers the texture (offset 0.5 is center). To make 
    // it grow from the left, we shift the texture's center point by half the 
    // non-visible area (1.0 - u_scale).
    // Formula: 0.5 - (u_scale / 2.0)
    llOwnerSay((string) u_scale);

    float u_offset = 0.25-(u_scale/2);
    llOwnerSay((string)u_offset);
    list params = [
        // Set the horizontal texture scale and offset on the specified face
		   PRIM_TEXTURE, TEXTURE_FACE, FILL_TEXTURE, 
        <0.5, 1.0, 0.0>,    // Scale: <U_scale, V_scale, Rotation>
        <u_offset, 0.0, 0.0>,   // Offset: <U_offset, V_offset, Repeat>
	0,
        // Update the floating text above the bar
        PRIM_TEXT, "Status: " + (string)llRound(g_bar_value) + "%", <1,1,1>, 1.0
    ];
    
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
        
        llSay(0, "Status Bar Initialized. Touch to cycle value.");
        
        // Initialize the bar to a starting value
        update_bar(g_bar_value);
    }
    
    // Use touch to demonstrate updating the bar value
    touch_start(integer num_detected)
    {
        // Only respond to the owner for safe testing
        if (llGetOwner() != llDetectedKey(0)) return;

        // Simple cycling logic for demonstration: decrease the value
        if (g_bar_value >= 100.0)
        {
            // If near min, jump to max value
            update_bar(0);
        }
        else
        {
            // Decrease value by 20
            update_bar(g_bar_value + 10.0);
        }
    }
}
