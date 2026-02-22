// Events for keyboard control
// assumes signature control(key id, integer held, integer change)

#define changing(x) change & x
#define up changing(CONTROL_UP)
#define down changing(CONTROL_DOWN)
#define fwd changing(CONTROL_FWD)
#define back changing(CONTROL_BACK)
#define rot_left changing(CONTROL_ROT_LEFT)
#define rot_right changing(CONTROL_ROT_RIGHT)
#define left changing(CONTROL_LEFT)
#define right changing(CONTROL_RIGHT)

#define holding(x) held & x
#define start_up holding(up)
#define start_down holding(down)
#define start_fwd holding(fwd)
#define start_back holding(back)
#define start_rot_left holding(rot_left)
#define start_rot_right holding(rot_right)
#define start_left holding(left)
#define start_right holding(right)

#define end_up (held == 0) && (up)
#define end_down (held == 0) && (down)
#define end_fwd (held == 0) && (fwd)
#define end_back (held == 0) && (back)
#define end_rot_left (held == 0) && (rot_left)
#define end_rot_right (held == 0) && (rot_right)
#define end_left (held == 0) && (left)
#define end_right (held == 0) && (right)

#define edge change == 0
#define cont_up (edge) && (holding(CONTROL_UP))
#define cont_down (edge) && (holding(CONTROL_DOWN))
#define cont_fwd (edge) && (holding(CONTROL_FWD))
#define cont_back (edge) && (holding(CONTROL_BACK))
#define cont_rot_left (edge) && (holding(CONTROL_ROT_LEFT))
#define cont_rot_right (edge) && (holding(CONTROL_ROT_RIGHT))
#define cont_left (edge) && (holding(CONTROL_LEFT))
#define cont_right (edge) && (holding(CONTROL_RIGHT))
