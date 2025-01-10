import 'dart:async';
import 'dart:io';

import 'package:blue_classic/BLUE_CODE/BLE/flll.dart';
import 'package:blue_classic/BLUE_CODE/CLASSIC/flu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth and Location Checker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isBluetoothEnabled = false;
  bool isLocationEnabled = false;
  bool isBluetoothSupported = true;
  StreamSubscription<BluetoothAdapterState>? bluetoothStateSubscription;

  final Location location = Location();

  @override
  void initState() {
    super.initState();
    initializeBluetoothAndLocation();
  }

  Future<void> initializeBluetoothAndLocation() async {
    // Check if Bluetooth is supported
    bool bluetoothSupported = await FlutterBluePlus.isSupported;
    if (!bluetoothSupported) {
      setState(() {
        isBluetoothSupported = false;
      });
      return;
    }

    // Handle Bluetooth adapter state
    bluetoothStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });

    // Turn on Bluetooth if possible
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // Check Location state
    checkLocationState();
  }

  Future<void> checkLocationState() async {
    bool locationPermissionGranted = await Permission.location.isGranted;
    if (!locationPermissionGranted) {
      await Permission.location.request();
    }

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    setState(() {
      isLocationEnabled = serviceEnabled;
    });
  }

  @override
  void dispose() {
    bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth & Location Checker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isBluetoothSupported)
              const Text(
                "Bluetooth is not supported on this device",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            if (isBluetoothSupported) ...[
              Text(
                "Bluetooth is ${isBluetoothEnabled ? "ON" : "OFF"}",
                style: TextStyle(
                  fontSize: 18,
                  color: isBluetoothEnabled ? Colors.green : Colors.red,
                ),
              ),
              Text(
                "Location is ${isLocationEnabled ? "ON" : "OFF"}",
                style: TextStyle(
                  fontSize: 18,
                  color: isLocationEnabled ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isBluetoothEnabled && isLocationEnabled
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyAppClassic()),
                        );
                      }
                    : null,
                child: const Text("Bluetooth Classic Devices"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isBluetoothEnabled && isLocationEnabled
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                    create: (_) => BluetoothProvider(),
                                    child: const MyAppBLE(),
                                  )),
                        );
                      }
                    : null,
                child: const Text("Bluetooth Light Energy Devices"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: initializeBluetoothAndLocation,
                child: const Text("Refresh State"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PageOne extends StatelessWidget {
  const PageOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Page One")),
      body: const Center(child: Text("This is Page One!")),
    );
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Page Two")),
      body: const Center(child: Text("This is Page Two!")),
    );
  }
}
