import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  final _log = <String>[];

  BluetoothServerSocket? _server;
  bool _starting = false;
  StreamSubscription<BluetoothConnection>? _serverSub;

  static const _defaultUuid = '00001101-0000-1000-8000-00805F9B34FB';
  static const _serviceName = 'FlutterBTExample';

  @override
  void dispose() {
    _serverSub?.cancel();
    _server?.close();
    super.dispose();
  }

  Future<void> _startServer() async {
    setState(() => _starting = true);
    try {
      final server = await _bluetooth.startServer(
        uuid: _defaultUuid,
        serviceName: _serviceName,
      );

      _serverSub = server.connections.listen((connection) {
        if (!mounted) return;
        setState(() {
          _log.add('Client connected: ${connection.address}');
        });
      });

      if (!mounted) return;
      setState(() {
        _server = server;
        _log.add('Server started — listening on $_serviceName');
      });
    } on BluetoothUnsupportedException catch (e) {
      _addLog('Not supported: ${e.feature} on ${e.platform}');
    } on BluetoothException catch (e) {
      _addLog('Error: ${e.message}');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stopServer() async {
    await _serverSub?.cancel();
    await _server?.close();
    if (!mounted) return;
    setState(() {
      _server = null;
      _log.add('Server stopped');
    });
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() => _log.add(msg));
  }

  @override
  Widget build(BuildContext context) {
    final running = _server != null;
    return Scaffold(
      appBar: AppBar(title: const Text('RFCOMM Server')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _starting ? null : (running ? _stopServer : _startServer),
        icon: _starting
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(running ? Icons.stop : Icons.play_arrow),
        label: Text(running ? 'Stop' : 'Start'),
      ),
      body: _log.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.router, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tap Start to begin listening',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UUID: $_defaultUuid',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _log[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
    );
  }
}
