#include "include/controlstack.h"
#include "include/sps.h"

#ifndef debug
#define debug(x)
#endif

#define UpdateTime 1

key handle_key;

key cyclist;
integer cyclist_channel;
integer cyclist_constitution;
integer channel;
integer handle;
float redlineSpeed;

float cardioF;
integer max_intensity;

integer speed;
float meters_per_second;
integer resistance;
float resistance_inverse_percent;

float start_time;
float exercise_start_time;
integer duration;

float xp;
float total_xp;
float fatigue;
float total_fatigue;
float total_distance;

integer hour;
integer minute;
integer second;

integer initialized;

GLOBAL_DATA;

#define SayToHud(x) llSay(cyclist_channel, (string)(x))

initialize() {
  if (initialized) return;
  initialized = TRUE;
  hour = minute = second = 0;
}

#define maxHeartRate  200 
#define baseRedline (2.0 * (resistance_inverse_percent / 2.0 + 0.5))
#define fitnessBonus 6.0

integer calculateHeartRate(float speedMps, float cardioFactor) {
  integer restingHeartRate = 95 - (integer) (50.0 * cardioFactor);
  if (speedMps <= 0) {
    return (integer) restingHeartRate;
  }
  float intensityPercent = speedMps / redlineSpeed * 0.85; // bike factor
    
  // 4. APPLY KARVONEN FORMULA
  // TargetHR = RestingHR + (HeartRateReserve * Intensity)
  integer hrReserve = maxHeartRate - restingHeartRate;
  integer currentBpm = restingHeartRate + (integer)(hrReserve * intensityPercent);
    
  // 5. CLAMP THE RESULTS
  if (currentBpm < restingHeartRate) currentBpm = restingHeartRate;
  if (currentBpm > maxHeartRate) currentBpm = maxHeartRate;
  return currentBpm;
}

//----------------------------------
// XP
// XP =Distance *((Tension/Max Force)^2 * Speed) * ( 1 + Fatigue^2 )
float xpGain(float distance, float resistance_percent, float s, float f) {
  return distance * resistance_percent * resistance_percent * s * (1 + f * f);
}

//----------------------------------
// Fat
//  Fatigue Rate = (Current Intensity - Endurance Threshold)  *Time) /Constitution Constant
//  Intensity = (Tension/Max Tension)^2 + ( Speed/Max Speed)^2
// Total Fatigue Increase = Fatigue Rate * ( 1 +  Current Fatigue^2)

float fatGain(float resist_percent, float speed_percent, float endurance, 
	      integer time, integer constitution, float f) {
  float intensity = resist_percent * resist_percent + speed_percent * speed_percent;
  float rate =  ((intensity - endurance) * time) / constitution;
  return rate * (1 + f * f);
}

// ---------------------------------------
compute(float distance, float resistance_percent, float speed_percent,
	float endurance, integer time, integer constitution) {
  float gain = fatGain(resistance_percent, speed_percent, endurance, time, constitution, fatigue);
  if (total_fatigue < 0) gain *= 2.0;
  fatigue = total_fatigue + gain;
  if (fatigue < -1) fatigue = -1;
  xp = total_xp + xpGain(distance, resistance_percent, meters_per_second, gain);
  debug((string) xp + " " + (string) fatigue);
}

// ---------------------------------------
setPower() {
  float watts = (resistance / 10.0) * max_intensity * meters_per_second;
  string units = " W";
  if (watts > 1000) {
    watts = watts / 1000.0;
    if (watts > 1000) {
      watts = watts / 1000;
      units = " MW";
    } else {
      units = " kW";
    }
  }
  llMessageLinked(LINK_THIS, 0, (string) ((integer)(watts + 0.5)) + units, "fw_data:Power");
}

// ---------------------------------------
setSpeed(integer speed, integer updateAnim) {
  string animation;
  string name;
  float liquid_inc;
  float now = llGetTime();
  string old_animation = animation;
  float mps = meters_per_second;
  float dist = (now - start_time) * meters_per_second;
  compute(dist,
	  resistance / 10.0,
	  meters_per_second / 5.5556,
	  cardioF * cardioF * 2,
	  (integer) (now - start_time),
	  cyclist_constitution);
  total_distance += dist;
  total_xp = xp;
  total_fatigue = fatigue;
  xp = 0;
  fatigue = 0;
  duration = 0;
  start_time = now;
  meters_per_second = speed / 3600.0;
  name = llGetSubString((string)(speed/1000.0),0,3) + " kM/H";
  integer speedkm = speed / 1000;
  if (speedkm <= 10) {
    animation = "bic-regular";
  } else if (speedkm <= 20) {
    animation = "bic-nohands";	
  }  else if (speedkm < 30) {
    animation = "bic-hill";
  } else {
    animation = "bic-fast";
  }

  integer hr = calculateHeartRate(meters_per_second, cardioF);
  if (hr >= maxHeartRate) { // beyond max
    speed = speed - 1000;
    meters_per_second = mps;
  } else {
    debug((string) hr + " " + (string) total_fatigue);
    if (updateAnim == TRUE) {
      if (animation != old_animation)
	llMessageLinked(LINK_THIS, SetSpeedAnimation, animation, cyclist);
      llMessageLinked(LINK_THIS, 0, name, "fw_data:Speed");
    }
    llMessageLinked(LINK_SET, WHEEL_SPEED, (string)(speedkm),NULL_KEY);
    llMessageLinked(LINK_THIS, 0, (string) hr + " BPM", "fw_data:Heart");
  }
}

default {
  on_rez(integer x) {
    initialize();
  }

  state_entry() {
    initialize();
    channel = (integer)("0x"+ llGetSubString((string) llGetKey(), -8, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE); 
  }
  
//----------------------------------
  link_message(integer from, integer chan, string msg, key xyzzy) {
    //    debug("workouts " + (string) chan + " " + msg);
    if (chan != InitializeWorkout &&
	chan != WorkoutReset &&
	chan != checkWorkout &&
	chan != publishSet &&
	chan != SpeedUp &&
	chan != SpeedDown &&
	chan != ResistUp &&
	chan != ResistDown &&
	chan != saveCardio &&
	chan != SetSpeed) return;
    debug("workout "+(string)chan);
    GET_CONTROL_GLOBAL;
    string a;
    switch (chan) {
    case InitializeWorkout: {
      debug("initialize");
      POP(a);
      fatigue = (float) a;
      POP(a);
      cardioF = (float) a;
      POP(a);
      max_intensity = (integer) a;
      speed = 3000;
      resistance = 1;
      resistance_inverse_percent = 1;
      cyclist = xyzzy;
      cyclist_constitution = (integer) (cardioF * 200 - 20);
      cyclist_channel = (integer)("0x"+ llGetSubString((string) cyclist, -8, -1));
      SayToHud("cardio|"+(string) channel + "|" + (string) LEGS_BIT);
      exercise_start_time = start_time = llGetTime();
      duration = 0;
      total_fatigue = fatigue;
      fatigue = 0;
      xp = 0;
      total_xp = 0;
      total_distance = 0;
      hour = minute = 0;
      second = 1;
      redlineSpeed = baseRedline + (fitnessBonus * cardioF);
      debug("redline speed is " + (string) redlineSpeed);
      setSpeed(speed, TRUE);
      setPower();
      llSetTimerEvent(UpdateTime);
      NEXT_STATE;
      break;
    }
    case saveCardio: {
      string json;
      POP(json);
      json = "{\"lifter\": \"" + (string) cyclist +
	"\", \"entry\": " + json +
	", \"cardio\": {\"distance\": "+(string) total_distance +
	", \"duration\": " + (string)(llGetTime() - exercise_start_time) +
	", \"type\": 1, \"redline\": " + (string) redlineSpeed + "}}";
      llMessageLinked(LINK_THIS, saveLifterStats,  "|save-cardio|" + json, cyclist);
      break;
    }
    case WorkoutReset: {
      if (cyclist_channel != 0) SayToHud("end-cardio");
      cyclist_channel = 0;
      //      llMessageLinked(LINK_THIS, saveLifterStats, export2Json(cyclist), cyclist);
      cyclist = NULL_KEY;      
      llListenControl(handle, FALSE);
      llSetTimerEvent(0);
      break;
    }
    case SetSpeed: { // TODO: Ramp up/down instead of sudden change
      llSetTimerEvent(0);
      integer old = speed;
      speed = (integer) msg;
      debug((string) speed);
      if (speed < 5000) speed = 5000;
      if (speed > 55000) speed = 55000;
      setSpeed(speed, speed != old);
      setPower();
      llSetTimerEvent(UpdateTime);
      break;
    }
    case SpeedUp: {   
      llSetTimerEvent(0);
      integer old = speed;
      speed += (integer) msg;
      debug((string) speed);
      if (speed < 5000) speed = 5000;
      if (speed > 55000) speed = 55000;
      setSpeed(speed, speed != old);
      setPower();
      llSetTimerEvent(UpdateTime);
      break;
    }
    case SpeedDown: {
      llSetTimerEvent(0);
      integer old = speed;
      speed -= (integer) msg;
      debug((string) speed);
      if (speed < 5000) speed = 5000;
      if (speed > 55000) speed = 55000;
      setSpeed(speed, speed != old);
      setPower();
      llSetTimerEvent(UpdateTime);
      break;
    }
    case publishSet: {
      debug("publish");
      llSetTimerEvent(0);
      float now = llGetTime();
      float dist = (now - start_time) * meters_per_second;
      compute(dist,
	      resistance / 10.0,
	      meters_per_second / 5.5556,
	      cardioF * cardioF * 2,
	      (integer) (now - start_time),
	      cyclist_constitution);
      total_distance += dist;
      total_xp = xp;
      total_fatigue = fatigue;

      debug("red line "+(string) ((total_distance / (llGetTime() - exercise_start_time)) / redlineSpeed));

      llMessageLinked(LINK_THIS, SaveLog, (string) saveCardio + "|1|" +
		      (string) total_xp + "|" + (string) total_fatigue + "|" + (string) LEGS_BIT, cyclist);
      NEXT_STATE;
      break;
    }
    default: break;
    }
  }

  timer() {
    duration += UpdateTime;
    float distance = meters_per_second * duration;
    float f = fatigue;
    string d;
    integer km = FALSE;
    if ((total_distance + distance) > 1000) {
      d = (string) ((total_distance + distance) / 1000.0);
      km = TRUE;
    } else{
      d = (string) (total_distance + distance);
    }
    integer x = llSubStringIndex(d, ".");
    if (x != -1) d = llGetSubString(d,0, x + 1);
    if (km) d = d + "Km"; else d = d + "m";
    compute(distance,
	    resistance / 10.0,
	    meters_per_second / 5.5556,
	    cardioF * cardioF * 2,
	    duration, cyclist_constitution);
    if (fatigue > 0.9) {
      resistance = 1;
      setSpeed(speed = 1, TRUE);
      SayToHud("info|Safety");
    } else if ((fatigue - f) < 0) {
      SayToHud("info|Recovery "+d);
    } else {
      SayToHud("info|Anaerobic "+d);
    }
    SayToHud("cardio-fatigue|" + (string) fatigue);
    second += UpdateTime;
    if (second >= 60) {
      second -= 60;
      minute++;
      if (minute >= 60) {
	minute -= 60;
	hour++;
      }
    }
    string time = (string) hour + ":";
    if (minute < 10) time = time + "0";
    time = time + (string) minute + ":";
    if (second < 10) time = time + "0";
    llMessageLinked(LINK_THIS, 0, time + (string) second, "fw_data:Time");
  }

  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) {
      state default;
    }
  }
}
