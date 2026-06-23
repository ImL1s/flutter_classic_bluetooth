import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import 'adapter_screen.dart';
import 'discovery_screen.dart';
import 'paired_screen.dart';
import 'server_screen.dart';
import 'capabilities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  bool? _supported;
  bool? _enabled;
  String? _error;
  StreamSubscription<BtcAdapterState>? _adapterSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final supported = await _bluetooth.isSupported();
      bool? enabled;
      if (supported) {
        enabled = await _bluetooth.isEnabled();
        _adapterSub = _bluetooth.adapterState.listen((state) {
          if (!mounted) return;
          setState(() {
            _enabled = state == BtcAdapterState.on;
          });
        });
      }
      if (!mounted) return;
      setState(() {
        _supported = supported;
        _enabled = enabled;
      });
    } on BtcException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Classic')),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : _supported == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(supported: _supported!, enabled: _enabled),
        const SizedBox(height: 16),
        _NavTile(
          icon: Icons.bluetooth,
          title: 'Adapter',
          subtitle: 'Adapter info, enable/disable',
          onTap: () => _push(context, const AdapterScreen()),
        ),
        _NavTile(
          icon: Icons.search,
          title: 'Discovery',
          subtitle: 'Scan for nearby devices',
          enabled: _supported! && (_enabled ?? false),
          onTap: () => _push(context, const DiscoveryScreen()),
        ),
        _NavTile(
          icon: Icons.devices,
          title: 'Paired Devices',
          subtitle: 'List bonded devices, connect',
          enabled: _supported! && (_enabled ?? false),
          onTap: () => _push(context, const PairedScreen()),
        ),
        _NavTile(
          icon: Icons.router,
          title: 'Server',
          subtitle: 'Start RFCOMM server',
          enabled: _supported! && (_enabled ?? false),
          onTap: () => _push(context, const ServerScreen()),
        ),
        _NavTile(
          icon: Icons.info_outline,
          title: 'Platform Capabilities',
          subtitle: 'Feature support matrix',
          onTap: () => _push(context, const CapabilitiesScreen()),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _StatusCard extends StatelessWidget {
  final bool supported;
  final bool? enabled;

  const _StatusCard({required this.supported, this.enabled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bluetooth Classic', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  supported ? Icons.check_circle : Icons.cancel,
                  color: supported ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(supported ? 'Hardware supported' : 'Not supported'),
              ],
            ),
            if (supported) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    enabled == true
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: enabled == true ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enabled == true ? 'Adapter enabled' : 'Adapter disabled',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
