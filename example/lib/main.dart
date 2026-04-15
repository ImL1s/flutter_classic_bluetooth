import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Unknown';
  final _bluetooth = FlutterClassicBluetooth();

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    String status;
    try {
      final supported = await _bluetooth.isSupported();
      if (!supported) {
        status = 'Bluetooth Classic not supported';
      } else {
        final enabled = await _bluetooth.isEnabled();
        status = enabled ? 'Bluetooth is enabled' : 'Bluetooth is disabled';
      }
    } on BluetoothException catch (e) {
      status = 'Error: ${e.message}';
    }

    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Bluetooth Classic Example')),
        body: Center(child: Text('Status: $_status\n')),
      ),
    );
  }
}
