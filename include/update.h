#define UPDATE_CHANNEL 120125
#define PowerRack  "[SPS] Power Rack"
#define PowerRackVersion [PowerRack, 0.1]
#define TrainersBoard ["[SPS] Trainers Board", 0.1]
#define TrainerConsole ["[SPS] Trainer Console", 0.1]
#define Vendor ["[SPS] Vendor", 0.1]
#define MassageTable ["[SPS] Massage Table", 0.1]
#define SPS_Devices PowerRack + TrainersBoard +TrainerConsole + Vendor + MassageTable
#define GetDevice(d) llListFindList(cSPS_Devices, [d])
#define GetDeviceVersion(i) (integer) cSPS_Devices[i+1]
#define GetVersionForDevice(d) GetDeviceVersion(GetDevice(d))
