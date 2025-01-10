import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ScanPage(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

// Scan Page
class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      List<BluetoothCharacteristic> writeCharacteristics = [];

      // Use the correct service and characteristic UUIDs
      const serviceUuid =
          "12345678-1234-5678-1234-56789abcdef0"; // ESP32 service UUID
      const characteristicUuid =
          "12345678-1234-5678-1234-56789abcdef1"; // ESP32 characteristic UUID

      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUuid &&
                (characteristic.properties.write ||
                    characteristic.properties.writeWithoutResponse)) {
              writeCharacteristics.add(characteristic);
            }
          }
        }
      }

      if (writeCharacteristics.isNotEmpty) {
        final characteristic = writeCharacteristics.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              device: device,
              characteristic: characteristic,
            ),
          ),
        ).then((_) {
          device.disconnect();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No writable characteristics found')),
        );
        device.disconnect();
      }
    } catch (e) {
      print('Error connecting to device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
      ),
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
                    onPressed: () => _connectToDevice(result.device),
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

// Message Page
class MessagePage extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const MessagePage({
    Key? key,
    required this.device,
    required this.characteristic,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      List<int> bytes = utf8.encode(_messageController.text);

      // Write to the characteristic
      await widget.characteristic.write(
        bytes,
        withoutResponse: false, // Use Write with Response
      );

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
        title: Text('Send to ${widget.device.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
