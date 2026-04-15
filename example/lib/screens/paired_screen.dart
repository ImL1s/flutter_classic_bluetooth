import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import 'connect_screen.dart';

class PairedScreen extends StatefulWidget {
  const PairedScreen({super.key});

  @override
  State<PairedScreen> createState() => _PairedScreenState();
}

class _PairedScreenState extends State<PairedScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  List<BluetoothDevice>? _devices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final devices = await _bluetooth.getPairedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _error = null;
      });
    } on BluetoothException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _unbond(BluetoothDevice device) async {
    try {
      final success = await _bluetooth.unbondDevice(device.address);
      if (success) {
        _showSnack('Unpaired ${device.displayName}');
        _load();
      } else {
        _showSnack('Failed to unpair');
      }
    } on BluetoothUnsupportedException {
      _showSnack('Unbond not supported on this platform');
    } on BluetoothException catch (e) {
      _showSnack(e.message);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : _devices == null
              ? const Center(child: CircularProgressIndicator())
              : _devices!.isEmpty
                  ? const Center(child: Text('No paired devices'))
                  : ListView.builder(
                      itemCount: _devices!.length,
                      itemBuilder: (context, index) {
                        final device = _devices![index];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
                          title: Text(device.displayName),
                          subtitle: Text(device.address),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'connect':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ConnectScreen(device: device),
                                    ),
                                  );
                                case 'unbond':
                                  _unbond(device);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'connect', child: Text('Connect')),
                              const PopupMenuItem(value: 'unbond', child: Text('Unbond')),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
