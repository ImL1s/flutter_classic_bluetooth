import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class CapabilitiesScreen extends StatefulWidget {
  const CapabilitiesScreen({super.key});

  @override
  State<CapabilitiesScreen> createState() => _CapabilitiesScreenState();
}

class _CapabilitiesScreenState extends State<CapabilitiesScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  BtcPlatformCapabilities? _caps;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final caps = await _bluetooth.getPlatformCapabilities();
      if (!mounted) return;
      setState(() => _caps = caps);
    } on BtcException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Capabilities')),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : _caps == null
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final caps = _caps!;
    final entries = <_CapEntry>[
      _CapEntry('Enable Bluetooth', caps.canEnableBluetooth),
      _CapEntry('Disable Bluetooth', caps.canDisableBluetooth),
      _CapEntry('Discover Devices', caps.canDiscoverDevices),
      _CapEntry('Get Paired Devices', caps.canGetPairedDevices),
      _CapEntry('Bond Devices', caps.canBondDevices),
      _CapEntry('Unbond Devices', caps.canUnbondDevices),
      _CapEntry('Create Server', caps.canCreateServer),
      _CapEntry('Set Discoverable', caps.canSetDiscoverable),
      _CapEntry('Multiple Connections', caps.supportsMultipleConnections),
      _CapEntry('Secure Connection', caps.supportsSecureConnection),
      _CapEntry('Insecure Connection', caps.supportsInsecureConnection),
      _CapEntry('Requires MFi', caps.requiresMfiCertification),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (caps.platformNote != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(caps.platformNote!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...entries.map((e) => _CapRow(entry: e)),
      ],
    );
  }
}

class _CapEntry {
  final String label;
  final bool value;

  const _CapEntry(this.label, this.value);
}

class _CapRow extends StatelessWidget {
  final _CapEntry entry;

  const _CapRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            entry.value ? Icons.check_circle : Icons.cancel,
            color: entry.value ? Colors.green : Colors.red.shade300,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(entry.label),
        ],
      ),
    );
  }
}
