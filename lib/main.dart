import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;

import 'package:volvophevapp/devices.dart';
import 'package:volvophevapp/obd.dart';

import 'obd.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volvo PHEV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool demoMode = false;
  BluetoothState currentBluetoothState = BluetoothState.UNKNOWN;
  ObdDeviceState currentObdState = ObdDeviceState.Unknown;
  BluetoothConnection currentDevice;
  String currentDeviceName;
  String inputData = "";
  Map<OBDDataType, String> obdValueMap = {};
  String versionString = "";

  @override
  void initState() {
    super.initState();

    Timer.periodic(
        Duration(seconds: 30),
        (timer) => {
              if (inputData.length > 0)
                sendDebugData("OBD input data: " + inputData)
            });

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        log("Initial BT state:" + state.toString());
        currentBluetoothState = state;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        currentBluetoothState = state;
        log("New BT state:" + state.toString());

        // Discoverable mode is disabled when Bluetooth gets disabled
        //_discoverableTimeoutTimer = null;
        //_discoverableTimeoutSecondsLeft = 0;
      });
    });

    getDevice().then((value) => {
          setState(() {
            currentDevice = value;
          })
        });

    PackageInfo.fromPlatform().then((info) => {
          setState(() {
            versionString = info.version + "+" + info.buildNumber;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Volvo Plug-in Hybrid Data'),
          actions: [
            IconButton(
              color: demoMode ? Colors.red : Colors.white24,
              icon: const Icon(Icons.support),
              onPressed: () {
                setState(() {
                  demoMode = !demoMode;
                });
              },
            ),
            IconButton(
                color: currentBluetoothState == BluetoothState.STATE_ON
                    ? Colors.green
                    : Colors.red,
                icon: const Icon(Icons.bluetooth),
                tooltip: "Connect to a device",
                onPressed: () {
                  showDeviceScreen(context);
                })
          ],
        ),
        body: Column(children: [
          demoMode
              ? MaterialBanner(
                  backgroundColor: Colors.red[100],
                  leading: CircleAvatar(
                    child: Icon(
                      Icons.support,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.red,
                  ),
                  content: Text("DEMO MODE ACTIVE",
                      style: TextStyle(color: Colors.red)),
                  actions: [
                      TextButton(
                        child: Text(
                          "Turn OFF",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          setState(() {
                            demoMode = false;
                          });
                        },
                      )
                    ])
              : Container(),
          currentBluetoothState == BluetoothState.UNKNOWN ||
                  currentBluetoothState == BluetoothState.STATE_OFF ||
                  currentBluetoothState == BluetoothState.ERROR ||
                  currentBluetoothState == BluetoothState.STATE_TURNING_OFF ||
                  currentBluetoothState == BluetoothState.STATE_BLE_TURNING_OFF
              ? MaterialBanner(
                  leading: CircleAvatar(child: Icon(Icons.bluetooth)),
                  content: Text("Bluetooth is turned OFF"),
                  actions: [
                    TextButton(
                      child: Text("Try again"),
                      onPressed: () {},
                    )
                  ],
                )
              : Container(),
          currentDeviceName == null || currentDeviceName == ''
              ? MaterialBanner(
                  leading: CircleAvatar(child: Icon(Icons.bluetooth)),
                  content: Text(
                      "You need to select a Bluetooth device to show data"),
                  actions: [
                    TextButton(
                        child: Text("Add device"),
                        onPressed: () {
                          showDeviceScreen(context);
                        })
                  ],
                  forceActionsBelow: false)
              : Container(),
          currentDeviceName != null && currentDevice == null
              ? MaterialBanner(
                  leading: CircleAvatar(child: Icon(Icons.bluetooth)),
                  content:
                      Text("Could not connect to device " + currentDeviceName),
                  actions: [
                    TextButton(
                        child: Text("Try again"),
                        onPressed: () {
                          getDevice().then((value) => {
                                setState(() {
                                  currentDevice = value;
                                })
                              });
                        })
                  ],
                  forceActionsBelow: false)
              : Container(),
          Expanded(child: _buildDataListView()),
          Text("Input data:" + inputData),
          Text(versionString, textAlign: TextAlign.center)
        ]));
  }

  Future<String> showDeviceScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DevicesPage()),
    );

    currentDevice = await getDevice();
    return result;
  }

  Future<http.Response> sendDebugData(String data) {
    final String url = "https://www.frazer.se/volvo.php?secret=abc123";
    return http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'data': data,
      }),
    );
  }

  Future<BluetoothConnection> getDevice() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.containsKey('bt.device.name') &&
        pref.containsKey('bt.device.address')) {
      currentDeviceName = pref.getString('bt.device.name');
      try {
        BluetoothConnection connection = await BluetoothConnection.toAddress(
            pref.getString('bt.device.address'));
        currentObdState = ObdDeviceState.Connected;
        connection.input.listen((Uint8List data) {
          String dataString = ascii.decode(data);

          if (dataString.trim().startsWith('ELM327 v2.0')) {
            // Init string recieved
            connection.output.add(ascii.encode('AT SP 0\r'));
            setState(() {
              currentObdState = ObdDeviceState.Ready;
            });
          } else {
            // Some other data recieved
            setState(() {
              obdValueMap.addAll(handleObdDataRecieved(dataString));
            });
          }

          setState(() {
            inputData += dataString + "\r\n";
          });
        });

        // Reset connection
        connection.output.add(ascii.encode('AT Z\r'));

        //connection.output.add(ascii.encode('0100\r'));
        return connection;
      } catch (e) {
        log("BT ERROR: " + e.toString());
        if (e.code == "connect_error")
          currentObdState = ObdDeviceState.Disconnected;
      }
    } else {
      currentObdState = ObdDeviceState.NotSet;
    }
    return null;
  }

  void sendDataRequest(OBDDataType dataType, BluetoothConnection connection) {
    if (connection.isConnected) {
      String commandToSend = getObdCommand(dataType);
      if (commandToSend != null) {
        commandToSend += "\r";

        connection.output.add(ascii.encode(commandToSend));
      }
    }
  }

  Widget _buildDataListView() {
    if (currentObdState == ObdDeviceState.Ready || demoMode) {
      if (demoMode) {
        obdValueMap[OBDDataType.ECT] =
            math.Random().nextInt(999).toString() + "C";
        obdValueMap[OBDDataType.RPM] =
            (math.Random().nextDouble() * 10000).toStringAsFixed(1);
      }

      return ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ListTile(
              title: const Text("Coolant Temp"),
              trailing: CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 5.0,
                  percent: 0.5,
                  center: Text(obdValueMap.containsKey(OBDDataType.ECT)
                      ? obdValueMap[OBDDataType.ECT]
                      : "N/A"),
                  progressColor: Colors.yellow),
              onTap: () {
                sendDataRequest(OBDDataType.ECT, currentDevice);
              }),
          ListTile(
              title: const Text("Engine RPM"),
              trailing: CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 5.0,
                  percent: 0.5,
                  center: Text(obdValueMap.containsKey(OBDDataType.RPM)
                      ? obdValueMap[OBDDataType.RPM]
                      : "N/A"),
                  progressColor: Colors.amber),
              onTap: () {
                sendDataRequest(OBDDataType.RPM, currentDevice);
              })
        ],
      );
    }

    return new Container();
  }
}
