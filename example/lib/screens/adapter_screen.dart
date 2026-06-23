import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class AdapterScreen extends StatefulWidget {
  const AdapterScreen({super.key});

  @override
  State<AdapterScreen> createState() => _AdapterScreenState();
}

class _AdapterScreenState extends State<AdapterScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  String? _name;
  String? _address;
  bool _enabled = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _bluetooth.isEnabled();
      String? name;
      String? address;
      if (enabled) {
        name = await _bluetooth.getAdapterName();
        address = await _bluetooth.getAdapterAddress();
      }
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _name = name;
        _address = address;
        _loading = false;
      });
    } on BtcException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _enable() async {
    try {
      await _bluetooth.enableBluetooth();
      _load();
    } on BtcUnsupportedException {
      _showSnack('Enable not supported on this platform');
    } on BtcException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _disable() async {
    try {
      await _bluetooth.disableBluetooth();
      _load();
    } on BtcUnsupportedException {
      _showSnack('Disable not supported on this platform');
    } on BtcException catch (e) {
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
      appBar: AppBar(title: const Text('Adapter')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('Status', _enabled ? 'Enabled' : 'Disabled'),
        if (_name != null) _InfoRow('Name', _name!),
        if (_address != null) _InfoRow('Address', _address!),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _enabled ? null : _enable,
                icon: const Icon(Icons.bluetooth),
                label: const Text('Enable'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _enabled ? _disable : null,
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Disable'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
