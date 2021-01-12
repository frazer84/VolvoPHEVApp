import 'package:flutter_test/flutter_test.dart';

import 'package:volvophevapp/obd.dart' as obd;

void main() {
  test('Get correct ascii code from enum', () async {
    String result = obd.getObdCommand(obd.OBDDataType.ECT);
    expect(result, equals('0105'));

    result = obd.getObdCommand(obd.OBDDataType.RPM);
    expect(result, equals('010C'));

    result = obd.getObdCommand(obd.OBDDataType.BatterySOC);
    expect(result, equals('224028'));
  });

  test('Get correct enum from data string', () async {
    obd.OBDDataType result = obd.obdDataTypeFromPid("05");
    expect(result, equals(obd.OBDDataType.ECT));

    result = obd.obdDataTypeFromPid("0C");
    expect(result, equals(obd.OBDDataType.RPM));

    result = obd.obdDataTypeFromPid("4028");
    expect(result, equals(obd.OBDDataType.BatterySOC));
  });

  test('Parse CORRECT data example (ECT)', () async {
    Map<obd.OBDDataType, String> result = obd.handleObdDataRecieved('41057B');
    expect(result.containsKey(obd.OBDDataType.ECT), true);
    expect(result[obd.OBDDataType.ECT], isNotNull);
    expect(result[obd.OBDDataType.ECT], "83C");
  });

  test('Parse INCORRECT data example (ECT)', () async {
    Map<obd.OBDDataType, String> result = obd.handleObdDataRecieved('40057B');
    expect(result.containsKey(obd.OBDDataType.ECT), false);
    expect(result[obd.OBDDataType.ECT], isNull);
  });

  test('Parse CORRECT data example (RPM)', () async {
    Map<obd.OBDDataType, String> result = obd.handleObdDataRecieved('410C1AF8');
    expect(result.containsKey(obd.OBDDataType.RPM), true);
    expect(result[obd.OBDDataType.RPM], isNotNull);
    expect(result[obd.OBDDataType.RPM], "1726.0");
  });

  test('Parse INCORRECT data example (RPM)', () async {
    Map<obd.OBDDataType, String> result = obd.handleObdDataRecieved('410C1AF9');
    expect(result.containsKey(obd.OBDDataType.RPM), true);
    expect(result[obd.OBDDataType.RPM], isNotNull);
    expect(result[obd.OBDDataType.RPM], isNot("1726.0"));
  });

  test('Parse CORRUPT data example', () async {
    Map<obd.OBDDataType, String> result = obd.handleObdDataRecieved('1234567');
    expect(result.containsKey(obd.OBDDataType.Unknown), true);
    expect(result[obd.OBDDataType.Unknown], isNotNull);
    expect(result[obd.OBDDataType.RPM], isNull);
    expect(result[obd.OBDDataType.ECT], isNull);
  });
}
