import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

/// A small app-state controller that wraps [FlutterClassicBluetooth] and exposes
/// reactive state to the UI. It is a plain [ChangeNotifier] (no extra packages)
/// so the example shows a pattern you can drop straight into a real app.
///
/// It owns the long-lived subscriptions (adapter state, discovery results and
/// discovery on/off) and keeps de-duplicated device lists that pages render via
/// [ListenableBuilder].
class BluetoothController extends ChangeNotifier {
  final FlutterClassicBluetooth bt = FlutterClassicBluetooth();

  bool _ready = false;

  /// Whether [init] has finished its first pass.
  bool get ready => _ready;

  bool _supported = false;
  bool get supported => _supported;

  BtcPlatformCapabilities caps = const BtcPlatformCapabilities();

  BtcAdapterState _adapterState = BtcAdapterState.unknown;
  BtcAdapterState get adapterState => _adapterState;

  /// Whether the adapter is powered on right now.
  bool get isOn => _adapterState == BtcAdapterState.on;

  String? adapterName;
  String? adapterAddress;

  bool _scanning = false;
  bool get scanning => _scanning;

  bool _loadingPaired = false;
  bool get loadingPaired => _loadingPaired;

  /// Most recent error message, surfaced by the UI as a banner/snackbar.
  String? lastError;

  final Map<String, BtcDevice> _discovered = {};

  /// Merges a follow-up discovery [update] onto a [previous] sighting of the
  /// same device, keeping earlier non-null fields. Some platforms emit later
  /// events (e.g. an RSSI refresh) that omit the name, which would otherwise
  /// blank it out and make the list show a bare MAC address.
  BtcDevice _mergeDevice(BtcDevice previous, BtcDevice update) {
    return BtcDevice(
      address: update.address,
      name: update.name ?? previous.name,
      alias: update.alias ?? previous.alias,
      rssi: update.rssi ?? previous.rssi,
      type: update.type != BtcDeviceType.unknown ? update.type : previous.type,
      bondState: update.bondState != BtcBondState.none
          ? update.bondState
          : previous.bondState,
      uuids: update.uuids.isNotEmpty ? update.uuids : previous.uuids,
    );
  }

  /// Devices found during the current/last scan, strongest signal first.
  List<BtcDevice> get discovered {
    final list = _discovered.values.toList();
    list.sort((a, b) => (b.rssi ?? -1000).compareTo(a.rssi ?? -1000));
    return list;
  }

  List<BtcDevice> _paired = const [];
  List<BtcDevice> get paired => _paired;

  StreamSubscription<BtcAdapterState>? _adapterSub;
  StreamSubscription<BtcDevice>? _resultsSub;
  StreamSubscription<bool>? _scanStateSub;

  /// Sets up capability detection and the long-lived listeners. Safe to call
  /// once at startup.
  Future<void> init() async {
    try {
      _supported = await bt.isSupported();
      caps = await bt.getPlatformCapabilities();

      if (_supported) {
        _adapterSub = bt.adapterState.listen((state) {
          final wasOn = isOn;
          _adapterState = state;
          if (isOn && !wasOn) {
            _refreshAdapterInfo();
            refreshPaired();
          }
          notifyListeners();
        });

        _resultsSub = bt.discoveryResults.listen((device) {
          final prev = _discovered[device.address];
          _discovered[device.address] = prev == null
              ? device
              : _mergeDevice(prev, device);
          notifyListeners();
        });

        _scanStateSub = bt.discoveryState.listen((scanning) {
          _scanning = scanning;
          notifyListeners();
        });

        await _refreshAdapterInfo();
        await refreshAdapterState();
      }
    } catch (e) {
      lastError = _describe(e);
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> _refreshAdapterInfo() async {
    try {
      adapterName = await bt.getAdapterName();
      adapterAddress = await bt.getAdapterAddress();
    } catch (_) {
      // Adapter name/address are best-effort (not available on every platform).
    }
  }

  /// Re-reads the adapter on/off state from the platform and updates the UI.
  ///
  /// Several platforms only emit an [FlutterClassicBluetooth.adapterState]
  /// snapshot when you subscribe, with no live push on change. Polling here
  /// after a toggle and on app resume keeps every page consistent regardless.
  Future<void> refreshAdapterState() async {
    if (!_supported) return;
    try {
      final wasOn = isOn;
      final enabled = await bt.isEnabled();
      final next = enabled ? BtcAdapterState.on : BtcAdapterState.off;
      if (next == _adapterState) return;
      _adapterState = next;
      if (isOn && !wasOn) {
        await _refreshAdapterInfo();
        await refreshPaired();
      }
      notifyListeners();
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
    }
  }

  Future<void> refreshPaired() async {
    if (!caps.canGetPairedDevices) return;
    _loadingPaired = true;
    notifyListeners();
    try {
      _paired = await bt.getPairedDevices();
    } catch (e) {
      lastError = _describe(e);
    } finally {
      _loadingPaired = false;
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    if (!caps.canDiscoverDevices || _scanning) return;
    _discovered.clear();
    notifyListeners();
    try {
      await bt.startDiscovery();
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    if (!_scanning) return;
    try {
      await bt.stopDiscovery();
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
    }
  }

  Future<void> toggleAdapter() async {
    try {
      if (isOn) {
        if (caps.canDisableBluetooth) await bt.disableBluetooth();
      } else {
        if (caps.canEnableBluetooth) await bt.enableBluetooth();
      }
      // The platform may not push an adapter-state event, so re-read it.
      await refreshAdapterState();
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
    }
  }

  Future<bool> setDiscoverable(int seconds) async {
    try {
      return await bt.setDiscoverable(seconds);
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> bond(BtcDevice device) async {
    try {
      final ok = await bt.bondDevice(device.address);
      await refreshPaired();
      return ok;
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unbond(BtcDevice device) async {
    try {
      final ok = await bt.unbondDevice(device.address);
      await refreshPaired();
      return ok;
    } catch (e) {
      lastError = _describe(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (lastError == null) return;
    lastError = null;
    notifyListeners();
  }

  String _describe(Object e) {
    if (e is BtcException) return e.message;
    return e.toString();
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _resultsSub?.cancel();
    _scanStateSub?.cancel();
    super.dispose();
  }
}
