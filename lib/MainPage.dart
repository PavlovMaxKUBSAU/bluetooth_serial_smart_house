import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

import './BackgroundCollectingTask.dart';
import './ChatPage.dart';
import './SelectBondedDevicePage.dart';


class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  late double optimalSize;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f1 = (MediaQuery.of(context).size.height - 50 - MediaQuery.of(context).padding.top) / 712;
    final f2 = MediaQuery.of(context).size.width / 468;
    optimalSize = f1<f2 ? f1*20 : f2*20;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text('Smart House'),
        centerTitle: true,
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            ListTile(
              title: const Text('MAC-адрес локального адаптера'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: const Text('Имя устройства'),
              subtitle: Text(_name),
              onLongPress: null,
            ),
            Divider(),
            ListTile(
              title: ElevatedButton(
                child: const Text('Подключить устройство'),
                onPressed: () async {
                  final BluetoothDevice? selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                        // return ChatPage(server: new BluetoothDevice(address: "1C:33:33:33:33:33", name: "Kotel"), optimalSize: optimalSize);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Подключение к ' + selectedDevice.address);
                    _startChat(context, selectedDevice);
                  } else {
                    print('Подключение: не выбрано');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server, optimalSize: optimalSize);
        },
      ),
    );
  }
}
