import 'dart:developer';

// https://www.motor-talk.de/forum/volvo-pids-t6412733.html?page=2

enum OBDDataType {
  Unknown,
  ECT,
  RPM,
  EngineLoad,
  VehicleSpeed,
  IntakeAirTemp,
  ThrottlePosition,
  FuelTankLevel,
  BatterySOC,
  BatteryCurrent,
  BatteryVoltage,
  SupportBatteryVoltage,
  DistanceToEmpty,
  EngineOilTemp,
  EngineOilLevel,
  EngineOilPressure,
  ACCTargetVehicleSpeed
}

Map<OBDDataType, String> obdPidMap = {
  OBDDataType.ECT: "05",
  OBDDataType.RPM: "0C",
  OBDDataType.EngineLoad: "04",
  OBDDataType.VehicleSpeed: "0D",
  OBDDataType.IntakeAirTemp: "0F",
  OBDDataType.ThrottlePosition: "11",
  OBDDataType.FuelTankLevel: "2F",
  OBDDataType.BatterySOC: "4028",
  OBDDataType.BatteryCurrent: "4090",
  OBDDataType.BatteryVoltage: "EE0B",
  OBDDataType.SupportBatteryVoltage: "417E",
  OBDDataType.DistanceToEmpty: "EEFD",
  OBDDataType.EngineOilTemp: "DA62",
  OBDDataType.EngineOilLevel: "DA63",
  OBDDataType.EngineOilPressure: "DA60",
  OBDDataType.ACCTargetVehicleSpeed: "DA12"
};

Map<OBDDataType, String> obdServiceMap = {
  OBDDataType.ECT: "01",
  OBDDataType.RPM: "01",
  OBDDataType.EngineLoad: "01",
  OBDDataType.VehicleSpeed: "01",
  OBDDataType.IntakeAirTemp: "01",
  OBDDataType.ThrottlePosition: "01",
  OBDDataType.FuelTankLevel: "01",
  OBDDataType.BatterySOC: "22",
  OBDDataType.BatteryCurrent: "22",
  OBDDataType.BatteryVoltage: "22",
  OBDDataType.SupportBatteryVoltage: "22",
  OBDDataType.DistanceToEmpty: "22",
  OBDDataType.EngineOilTemp: "22",
  OBDDataType.EngineOilLevel: "22",
  OBDDataType.EngineOilPressure: "22",
  OBDDataType.ACCTargetVehicleSpeed: "22"
};

OBDDataType obdDataTypeFromPid(String pid) {
  OBDDataType dataType = obdPidMap.keys
      .firstWhere((key) => obdPidMap[key] == pid, orElse: () => null);
  if (dataType != null) return dataType;
  return OBDDataType.Unknown;
}

enum ObdDeviceState {
  Unknown,
  NotSet,
  NotFound,
  Disconnected,
  Connected,
  Ready
}

String getObdCommand(OBDDataType dataType) {
  if (obdServiceMap.containsKey(dataType) && obdPidMap.containsKey(dataType))
    return obdServiceMap[dataType] + obdPidMap[dataType];
  return null;
}

Map<OBDDataType, String> handleObdDataRecieved(String data) {
  if (data.substring(0, 2) == "41") {
    // Response to a 01 request
    switch (obdDataTypeFromPid(data.substring(2, 4))) {
      case OBDDataType.ECT:
        return {
          OBDDataType.ECT:
              (int.parse("0x" + data.substring(4, 6)) - 40).toString() + "C"
        };
        break;
      case OBDDataType.RPM:
        return {
          OBDDataType.RPM:
              (int.parse("0x" + data.substring(4, 8)) / 4).toString()
        };
        break;
      default:
        log("Unknown PID recieved");
        break;
    }
  }
  return {OBDDataType.Unknown: ""};
}
