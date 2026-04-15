import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import 'connect_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  final _devices = <BluetoothDevice>[];
  bool _discovering = false;
  StreamSubscription<BluetoothDevice>? _resultsSub;
  StreamSubscription<bool>? _stateSub;

  @override
  void initState() {
    super.initState();
    _resultsSub = _bluetooth.discoveryResults.listen((device) {
      if (!mounted) return;
      setState(() {
        final idx = _devices.indexWhere((d) => d.address == device.address);
        if (idx >= 0) {
          _devices[idx] = device;
        } else {
          _devices.add(device);
        }
      });
    });
    _stateSub = _bluetooth.discoveryState.listen((discovering) {
      if (!mounted) return;
      setState(() => _discovering = discovering);
    });
  }

  @override
  void dispose() {
    _resultsSub?.cancel();
    _stateSub?.cancel();
    if (_discovering) _bluetooth.stopDiscovery();
    super.dispose();
  }

  Future<void> _toggleDiscovery() async {
    try {
      if (_discovering) {
        await _bluetooth.stopDiscovery();
      } else {
        setState(() => _devices.clear());
        await _bluetooth.startDiscovery();
        setState(() => _discovering = true);
      }
    } on BluetoothUnsupportedException catch (e) {
      _showSnack('${e.feature} not supported on ${e.platform}');
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
        title: const Text('Discovery'),
        actions: [
          if (_discovering) const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleDiscovery,
        icon: Icon(_discovering ? Icons.stop : Icons.search),
        label: Text(_discovering ? 'Stop' : 'Scan'),
      ),
      body: _devices.isEmpty
          ? Center(
              child: Text(
                _discovering ? 'Scanning...' : 'Tap Scan to find devices',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return _DeviceTile(
                  device: device,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConnectScreen(device: device),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        device.bondState == BluetoothBondState.bonded
            ? Icons.bluetooth_connected
            : Icons.bluetooth,
        color: device.bondState == BluetoothBondState.bonded
            ? Colors.blue
            : null,
      ),
      title: Text(device.displayName),
      subtitle: Text(
        '${device.address}'
        '${device.rssi != null ? ' • ${device.rssi} dBm' : ''}'
        '${device.type != BluetoothDeviceType.unknown ? ' • ${device.type.name}' : ''}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
