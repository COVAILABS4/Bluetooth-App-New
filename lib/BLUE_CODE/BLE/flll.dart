import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BluetoothProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainPage(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

// Bluetooth Provider
class BluetoothProvider extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Connect to the Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      notifyListeners();
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  // Clear the connected Bluetooth device
  Future<void> clearConnectedDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      notifyListeners();
    }
  }
}

// Main Page (App Bar with Bluetooth button)
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Future<void> _showBluetoothDevices(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BluetoothDeviceList(
          onDeviceSelected: (BluetoothDevice device) {
            Navigator.pop(context); // Close the modal
            _connectToDevice(context, device);
          },
        );
      },
    );
  }

  Future<void> _connectToDevice(
      BuildContext context, BluetoothDevice device) async {
    final provider = Provider.of<BluetoothProvider>(context, listen: false);
    await provider.connectToDevice(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => _showBluetoothDevices(context),
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, _) {
          return provider.connectedDevice == null
              ? const Center(child: Text('No device connected'))
              : DeviceMessagePage(
                  device: provider.connectedDevice!,
                  onDisconnect: () async {
                    await provider.clearConnectedDevice(); // Disconnect device
                  },
                );
        },
      ),
    );
  }
}

// Bluetooth Device List in Modal
class BluetoothDeviceList extends StatefulWidget {
  final Function(BluetoothDevice) onDeviceSelected;

  const BluetoothDeviceList({Key? key, required this.onDeviceSelected})
      : super(key: key);

  @override
  _BluetoothDeviceListState createState() => _BluetoothDeviceListState();
}

class _BluetoothDeviceListState extends State<BluetoothDeviceList> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  Future<void> _startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    try {
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      print('Error starting scan: $e');
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Bluetooth Device')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  title: Text(result.device.name.isEmpty
                      ? 'Unknown Device'
                      : result.device.name),
                  subtitle: Text(result.device.id.id),
                  trailing: ElevatedButton(
                    child: const Text('Connect'),
                    onPressed: () => widget.onDeviceSelected(result.device),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? null : _startScan,
        child: isScanning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.bluetooth_searching),
      ),
    );
  }
}

// Device Message Page (where you can send messages to the device)
class DeviceMessagePage extends StatefulWidget {
  final BluetoothDevice device;
  final Future<void> Function() onDisconnect;

  const DeviceMessagePage({
    Key? key,
    required this.device,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  _DeviceMessagePageState createState() => _DeviceMessagePageState();
}

class _DeviceMessagePageState extends State<DeviceMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  BluetoothCharacteristic? _characteristic;

  @override
  void initState() {
    super.initState();
    _findWritableCharacteristic();
  }

  Future<void> _findWritableCharacteristic() async {
    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            setState(() {
              _characteristic = characteristic;
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error discovering services: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _characteristic == null) return;

    try {
      List<int> bytes = utf8.encode(_messageController.text);
      await _characteristic!.write(bytes, withoutResponse: false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device: ${widget.device.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: widget.onDisconnect,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Connected to: ${widget.device.name}\nMAC Address: ${widget.device.id.id}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Enter message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
