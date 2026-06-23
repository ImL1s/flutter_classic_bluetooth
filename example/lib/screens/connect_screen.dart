import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class ConnectScreen extends StatefulWidget {
  final BtcDevice device;

  const ConnectScreen({super.key, required this.device});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _log = <_LogEntry>[];

  BtcConnection? _connection;
  bool _connecting = false;
  StreamSubscription<Uint8List>? _dataSub;

  static const _defaultUuid = '00001101-0000-1000-8000-00805F9B34FB';

  @override
  void dispose() {
    _dataSub?.cancel();
    _connection?.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final connection = await _bluetooth.connect(
        address: widget.device.address,
        uuid: _defaultUuid,
      );
      _dataSub = connection.input.listen(
        (data) {
          if (!mounted) return;
          setState(() {
            _log.add(
              _LogEntry(
                direction: _Direction.received,
                text: utf8.decode(data, allowMalformed: true),
                bytes: data,
              ),
            );
          });
          _scrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _connection = null;
            _log.add(
              _LogEntry(
                direction: _Direction.system,
                text: 'Connection closed',
              ),
            );
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _connection = connection;
        _log.add(
          _LogEntry(
            direction: _Direction.system,
            text: 'Connected to ${widget.device.displayName}',
          ),
        );
      });
    } on BtcException catch (e) {
      if (!mounted) return;
      setState(() {
        _log.add(
          _LogEntry(direction: _Direction.system, text: 'Error: ${e.message}'),
        );
      });
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _dataSub?.cancel();
    await _connection?.close();
    if (!mounted) return;
    setState(() {
      _connection = null;
      _log.add(_LogEntry(direction: _Direction.system, text: 'Disconnected'));
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _connection == null) return;

    final data = Uint8List.fromList(utf8.encode('$text\n'));
    try {
      _connection!.output.add(data);
      setState(() {
        _log.add(
          _LogEntry(direction: _Direction.sent, text: text, bytes: data),
        );
      });
      _inputController.clear();
      _scrollToBottom();
    } on BtcException catch (e) {
      setState(() {
        _log.add(
          _LogEntry(
            direction: _Direction.system,
            text: 'Send error: ${e.message}',
          ),
        );
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connection != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.displayName),
        actions: [
          if (_connecting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(connected ? Icons.link_off : Icons.link),
              onPressed: connected ? _disconnect : _connect,
              tooltip: connected ? 'Disconnect' : 'Connect',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      connected
                          ? 'Connected — send a message'
                          : 'Tap link icon to connect',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _log.length,
                    itemBuilder: (context, index) =>
                        _LogTile(entry: _log[index]),
                  ),
          ),
          if (connected)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'Type message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Direction { sent, received, system }

class _LogEntry {
  final _Direction direction;
  final String text;
  final Uint8List? bytes;
  final DateTime time = DateTime.now();

  _LogEntry({required this.direction, required this.text, this.bytes});
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;

  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (entry.direction) {
      case _Direction.sent:
        color = Colors.blue;
        icon = Icons.arrow_upward;
      case _Direction.received:
        color = Colors.green;
        icon = Icons.arrow_downward;
      case _Direction.system:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    final time =
        '${entry.time.hour.toString().padLeft(2, '0')}:'
        '${entry.time.minute.toString().padLeft(2, '0')}:'
        '${entry.time.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(color: color, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
