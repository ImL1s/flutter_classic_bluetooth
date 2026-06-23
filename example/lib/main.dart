import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const BluetoothExampleApp());
}

class BluetoothExampleApp extends StatelessWidget {
  const BluetoothExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Classic Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
