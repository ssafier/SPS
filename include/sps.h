#define VERSION "0.05"

// configuration menu
#define doMenu 2
#define getLeaf 4
#define returnLeaf 5
#define MENU_FAIL 6
#define positionSitter2 7

// animation flags
#define afStopAll 1
#define afCache 2
#define afReplace 4
#define afLoop 8 // loop

// animation states
#define doAnimations 16
#define doAnimate 17
#define resetAnimationState 18
#define devMuscleFlex 19

// infinite weight system
#define rezWeights 100
#define weightsRezzed 101
#define selectWeight 102

// for boards
#ifndef renderImage
#define renderImage 107
#endif

// machine states
#define SetLifter 1001
#define InUse 1001
#define ClearLifter 1002
//#define ConfigureForWorkout 1003
#define ConfigureEquipment 1004
#define ResetEquipment 1005
#define ResetWorkout 1007
#define ReadyForLifter 1008
#define ReStand 1009
#define Lifting 1010
#define LiftingDone 1011
#define InitializeWorkout 1012
#define WorkoutReset 1013
#define WorkoutInitialized 1014
#define NewWorkout 1015
#define chooseWeight 1016
#define getRep 1017
#define returnRep 1018
#define sitLifter 1019
#define publishSet 1020
#define stopLifting 1021
#define cacheRep 1022
#define initBarAndWeights 1023
#define barAndWeightsRezzed 1024
#define resetBarAndWeights 1025
#define restInterval 1026
#define Rested 1027
#define publishSetForSpotter 1028
#define getPosFromConfig 1029
#define returnPosLeaf 1030
#define initiateStand 1031
#define returnIntensityLeaf 1032
#define getPosForEquipment 1033
#define returnPosKeepAnim 1034
#define initializeLifter 1035
#define startResting 1036
#define setupRack 1037
#define saveLifterStats 1038
#define checkSpotterMenu 1039
#define resetTrainer 1040
#define animateWithSpotter 1041
#define saveSpotter 1042
#define checkWorkoutFail 1043
#define checkWorkout 1044
#define resetWeights 1045
#define configureBar 1046
#define incrementLifterPos 1047
#define savePositions 1048

// bench
#define FlatBench 2000
#define InclineBench 2001
#define MoveBench 2002

// hud interface
#define testHudCheck 3000
#define testHudCheckPass 3001
#define testHudCheckFail -3001

// body parts
#define ARMS_BIT 1
#define CORE_BIT 2
#define CHEST_BIT 4
#define BACK_BIT 8
#define LEGS_BIT 16
#define ALL_BODY_PARTS 31

// strings for the states
#define sConfigureEquipment "1004"
#define sReStand "1009"
#define sLiftingDone "1011"
#define sInitializeWorkout "1012"
#define sWorkoutInitialized "1014"
#define sNewWorkout "1015"
#define sChooseWeight "1016"
#define sReturnRep "1018"
#define sSitLifter "1019"
#define sCacheRep "1022"
#define sInitiateStand "1031"
#define sInitializeLifter "1035"
#define sSetupRack "1037"

// HUD messages
#define UpdateStatus 100
#define StartClock 101
#define StopClock -101
#define updateFromServer 102
#define reStartClock 103
#define infoTick 104
#define startInfoClock 105
#define stopInfoClock 106

// MassageTable
#define setClient 1000
#define getMasseur 1001
#define updateMasseur 1002
#define updateClient 1003
#define resetTable 1004
#define massageReady 1005
#define initializeSitter 1006
#define signalReset 1007
#define bothSeated 1008
#define saveAndSignalReset 1009
#define SaveMassage 1010

// Trainers console
#define checkVisitors 10000
#define noAgents 10001
#define updateVisitors 10002
#define checkArrivals 10003
#define noChange 10004
#define setTrainers 10005
#define addTrainer 10006
#define removeTrainer 10007
#define trainerAvailable 10008

// trainer API
#define getTrainer 10100
#define menuTrainer 10101
#define checkTrainer 10102
#define setTrainer 10103
#define setTrainerFail 10104
#define testTrainerNotClientPass 10105
#define testTrainerNotClientFail 10106
#define testTrainerNotClient 10107
#define freeTrainer 10108
#define disallowTrainer 10109
#define testTrainer 10110
#define isTrainerPass 10111
#define isNotTrainer 10112
#define isTrainer 10113

#define TrainerChannel -20251031
#define AvailableTrainerChannel -20251101
#define TrainerQueryChannel 20251102
#define TrainerResponseChannel -20251102

#define noTrainers(x) (x == "")
#define registerTrainers 20251031
#define clearTrainers 20251101

// Supplements
#define trEnergy 1
#define creatine 2
#define menthol 3
#define protein_shake 4

// Vendor
#define requestHUD 200
#define giveHUD 201
#define transferSML 202
#define restartTimer 204
#define confirmPurchase 205

// Hydraulics
#define PISTON_VAL 250
#define PISTON_SIZE 251
#define HYDRAULIC_ON 252
#define HYDRAULIC_OFF 253
#define START_HYDRAULICS 254
#define STOP_HYDRAULICS 255

// Gears (dup of hydraulics)
#define GEAR_ON 252
#define GEAR_OFF 253
#define GEAR_SPEED 254

// Treadmill
#define SetSpeedAnimation 256
#define SetTreadmill 257
#define FishOff 258
#define SpeedUp 259
#define SpeedDown 260
#define ResistUp 261
#define ResistDown 262
#define saveCardio 263
#define SetSpeed 264
#define SpeedTouch 265
#define ResistTouch 266
#define TreadmillMenu 267
#define sTreadmillMenu "267"
#define activateButtons 268
#define deactivateButtons -268
#define setResistText 269
#define setSpeedText 270

#define TextButton 998

// Workout Logs
#define INIT 0
#define CARDIO 1
#define STRENGTH 2
#define REHAB 3
#define REST 4
#define STRETCH 5

// Cardio types
#define CARDIO_OTHER 0
#define RUN 1
#define CYCLE 2
#define ROW 3

#define StartLog 300
#define SaveLog 301
#define ResetLog 302

#define Yoga 400
#define EndSession 401
#define getLeafCheckClass 402
#define checkClass 403
#define joinClass 404
#define leaveClass 405
#define endClass 406
#define stopClassCheck 407
#define animateClass 408
#define saveClass 409
#define incrementClassPay 410
