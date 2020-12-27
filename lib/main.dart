import 'package:flutter/material.dart';
import 'package:volvophevapp/devices.dart';
import 'package:percent_indicator/percent_indicator.dart';

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

  String btDeviceId;
  final bool btConnected = false;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Volvo Plug-in Hybrid Data'),
          actions: [
            IconButton(
                icon: const Icon(Icons.bluetooth),
                tooltip: "Connect to a device",
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return DevicesPage();
                  })).then((value) => {
                            setState(() {
                              widget.btDeviceId = value;
                            })
                          });
                })
          ],
        ),
        body: Column(children: [
          widget.btDeviceId == null
              ? MaterialBanner(
                  leading: CircleAvatar(child: Icon(Icons.bluetooth)),
                  content: Text(
                      "You need to select a Bluetooth device to show data"),
                  actions: [
                    TextButton(
                        child: Text("Add device"),
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return DevicesPage();
                          })).then((value) => {
                                    setState(() {
                                      widget.btDeviceId = value;
                                    })
                                  });
                        })
                  ],
                  forceActionsBelow: false)
              : Container(),
          widget.btDeviceId != null && !widget.btConnected
              ? MaterialBanner(
                  leading: CircleAvatar(child: Icon(Icons.bluetooth)),
                  content:
                      Text("Unable to connect to your paired Bluetooth device"),
                  actions: [
                    TextButton(
                        child: Text("Try again"),
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return DevicesPage();
                          }));
                        })
                  ],
                  forceActionsBelow: false)
              : Container(),
          Expanded(child: _buildDataListView()),
        ]));
  }

  ListView _buildDataListView() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ListTile(
            title: const Text("Hybrid battery level"),
            trailing: CircularPercentIndicator(
                radius: 50.0,
                lineWidth: 5.0,
                percent: 0.5,
                center: new Text("50%"),
                progressColor: Colors.yellow))
      ],
    );
  }
}
