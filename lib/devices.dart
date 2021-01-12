import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicesPage extends StatefulWidget {
  DevicesPage({Key key}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  StreamSubscription<BluetoothDiscoveryResult> listenSubscription;
  List<BluetoothDiscoveryResult> devicesList = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    // Scan
  }

  @override
  void dispose() {
    listenSubscription?.cancel();
    // stop scan
    super.dispose();
  }

  void _startDiscovery() {
    devicesList.clear();
    listenSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      if (!devicesList.contains(r)) {
        setState(() {
          devicesList.add(r);
        });
      }
    });
  }

  void _stopDiscovery() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Connect to a OBDII-device"),
        ),
        body: _buildListViewOfDevices());
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDiscoveryResult device in devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.device.name == '' || device.device.name == null
                        ? '(Unknown device)'
                        : device.device.name),
                    Text(device.device.address.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _stopDiscovery();
                  SharedPreferences.getInstance().then((value) => {
                        value.setString(
                            'bt.device.address', device.device.address),
                        value.setString('bt.device.name', device.device.name),
                        Navigator.of(context).pop(device.device.address)
                      });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  /*_addDeviceTolist(final BluetoothDiscoveryResult device) {
    if (!devicesList.contains(device)) {
      setState(() {
        devicesList.add(device);
      });
    }
  }*/
}
