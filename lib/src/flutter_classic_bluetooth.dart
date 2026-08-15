import 'dart:io';

import 'btc_uuid.dart';
import 'btc_reconnecting_connection.dart';
import 'platform_interface.dart';
import 'models/btc_enums.dart';
import 'models/btc_reconnect_policy.dart';
import 'models/btc_connection.dart';
import 'models/btc_device.dart';
import 'models/btc_server_socket.dart';
import 'models/btc_platform_capabilities.dart';
import 'models/btc_exceptions.dart';

/// Primary API for Bluetooth Classic operations.
///
/// Provides a unified interface across Android, iOS (MFi only), Windows,
/// macOS, and Linux for discovering, pairing, and communicating with
/// Bluetooth Classic devices over RFCOMM.
///
/// ```dart
/// final bluetooth = FlutterClassicBluetooth();
///
/// // Check platform capabilities
/// final caps = await bluetooth.getPlatformCapabilities();
///
/// // Discover devices
/// if (caps.canDiscoverDevices) {
///   bluetooth.discoveryResults.listen((device) {
///     print('Found: ${device.displayName}');
///   });
///   await bluetooth.startDiscovery();
/// }
///
/// // Connect and communicate
/// final connection = await bluetooth.connect(
///   address: 'AA:BB:CC:DD:EE:FF',
///   uuid: '00001101-0000-1000-8000-00805F9B34FB',
/// );
/// connection.input.listen((data) => print('Received: $data'));
/// await connection.output.add(Uint8List.fromList([0x01, 0x02]));
/// await connection.finish();
/// ```
///
/// {@category Core}
class FlutterClassicBluetooth {
  FlutterClassicBluetooth._();
  static final FlutterClassicBluetooth _instance = FlutterClassicBluetooth._();

  /// Returns the singleton instance of [FlutterClassicBluetooth].
  factory FlutterClassicBluetooth() => _instance;

  FlutterClassicBluetoothPlatform get _platform =>
      FlutterClassicBluetoothPlatform.instance;

  // ── Regular expression patterns for validation ───────────────────────

  static final _macAddressRegex = RegExp(
    r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$',
  );

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // ── Adapter ──────────────────────────────────────────────────────────

  /// Returns whether Bluetooth Classic hardware is available on this device.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | Yes |
  Future<bool> isSupported() => _platform.isSupported();

  /// Returns whether the Bluetooth adapter is currently enabled.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | ⚠️ (CoreBluetooth radio state; MFi-accessory fallback until known) |
  Future<bool> isEnabled() => _platform.isEnabled();

  /// Requests the system to enable the Bluetooth adapter.
  ///
  /// Returns `true` if Bluetooth was enabled or was already on.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes (system dialog) |
  /// | Windows | No |
  /// | macOS | No |
  /// | Linux | Yes (BlueZ D-Bus) |
  /// | iOS | No |
  Future<bool> enableBluetooth() => _platform.enableBluetooth();

  /// Requests the system to disable the Bluetooth adapter.
  ///
  /// Returns `true` if Bluetooth was disabled or was already off.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes (API < 33 only) |
  /// | Windows | No |
  /// | macOS | No |
  /// | Linux | Yes (BlueZ D-Bus) |
  /// | iOS | No |
  Future<bool> disableBluetooth() => _platform.disableBluetooth();

  /// Stream of adapter state changes.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes (current state on listen) |
  /// | macOS | Yes (current state on listen) |
  /// | Linux | Yes (current state on listen) |
  /// | iOS | Yes (CoreBluetooth radio state) |
  Stream<BtcAdapterState> get adapterState => _platform.adapterState();

  /// Returns the local adapter's friendly name.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No |
  Future<String?> getAdapterName() => _platform.getAdapterName();

  /// Returns the local adapter's hardware address (MAC).
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ⚠️ (returns "02:00:00:00:00:00" on API 23+) |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No |
  Future<String?> getAdapterAddress() => _platform.getAdapterAddress();

  // ── Discovery ────────────────────────────────────────────────────────

  /// Starts discovering nearby Bluetooth Classic devices.
  ///
  /// Listen to [discoveryResults] for found devices and [discoveryState]
  /// for discovery start/stop events.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No |
  Future<void> startDiscovery() => _platform.startDiscovery();

  /// Stops an ongoing device discovery.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No |
  Future<void> stopDiscovery() => _platform.stopDiscovery();

  /// Returns whether a discovery scan is currently in progress.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No (always returns false) |
  Future<bool> isDiscovering() => _platform.isDiscovering();

  /// Stream that emits `true` when discovery starts and `false` when it stops.
  Stream<bool> get discoveryState => _platform.discoveryState();

  /// Stream of devices found during discovery.
  Stream<BtcDevice> get discoveryResults => _platform.discoveryResults();

  /// Runs a single bounded scan and returns the devices found.
  ///
  /// Convenience wrapper over [startDiscovery] + [discoveryResults]: it starts
  /// discovery, collects results for [timeout] (de-duplicated by address and
  /// merged so a device keeps its name across partial updates), stops
  /// discovery, and returns the list sorted by signal strength (strongest
  /// first). For a live feed, use [startDiscovery]/[discoveryResults] directly.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No (throws [BtcUnsupportedException]) |
  Future<List<BtcDevice>> scan({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final found = <String, BtcDevice>{};
    final sub = discoveryResults.listen((device) {
      final prev = found[device.address];
      found[device.address] = prev == null ? device : prev.mergedWith(device);
    });
    try {
      await startDiscovery();
      await Future<void>.delayed(timeout);
    } finally {
      try {
        await stopDiscovery();
      } catch (_) {
        // Discovery may already have stopped; ignore.
      }
      await sub.cancel();
    }
    final list = found.values.toList()
      ..sort((a, b) => (b.rssi ?? -1000).compareTo(a.rssi ?? -1000));
    return list;
  }

  // ── Pairing ──────────────────────────────────────────────────────────

  /// Returns the list of currently paired/bonded devices.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes (BlueZ D-Bus) |
  /// | iOS | Yes (connected MFi accessories) |
  Future<List<BtcDevice>> getPairedDevices() => _platform.getPairedDevices();

  /// Initiates pairing with the device at [address].
  ///
  /// Returns `true` if bonding succeeded.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes (system dialog) |
  /// | macOS | Yes (IOBluetoothDevicePair; may show a system prompt) |
  /// | Linux | Yes (BlueZ D-Bus; PIN/passkey devices need a system agent) |
  /// | iOS | No |
  ///
  /// Throws [BtcAddressException] if [address] is not a valid MAC.
  Future<bool> bondDevice(String address) {
    _validateAddress(address);
    return _platform.bondDevice(address);
  }

  /// Removes the bond with the device at [address].
  ///
  /// Returns `true` if the bond was successfully removed.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | No (unpair via System Settings) |
  /// | Linux | Yes (BlueZ D-Bus) |
  /// | iOS | No |
  ///
  /// Throws [BtcAddressException] if [address] is not a valid MAC.
  Future<bool> unbondDevice(String address) {
    _validateAddress(address);
    return _platform.unbondDevice(address);
  }

  /// Stream of bond state changes for a specific device.
  ///
  /// Throws [BtcAddressException] if [address] is not a valid MAC.
  Stream<BtcBondState> bondState(String address) {
    _validateAddress(address);
    return _platform.bondState(address);
  }

  // ── Connection ───────────────────────────────────────────────────────

  /// Connects to the device at [address] using the given [uuid].
  ///
  /// [uuid] defaults to [BtcUuid.spp] (the Serial Port Profile), which is what
  /// HC-05/HC-06, ESP32/ESP8266, Arduino, and most serial devices use. So for
  /// the common case you only need `connect(address: ...)`.
  ///
  /// If [secure] is `true` (default), uses authenticated/encrypted RFCOMM.
  /// Returns a [BtcConnection] for reading/writing data.
  ///
  /// If [timeout] is provided, the attempt fails with a [BtcTimeoutException]
  /// when it does not complete in time. Note: the native connection attempt may
  /// still resolve afterwards on some platforms; the returned connection (if
  /// any) is then orphaned. Call [disconnect] if you track its id.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | ⚠️ (MFi accessories via protocol string) |
  ///
  /// [channel] connects to an explicit RFCOMM channel instead of looking the
  /// service up by [uuid]. Use it for devices that do not publish a usable SPP
  /// service record — a large family of cheap serial adapters, ELM327 OBD-II
  /// clones especially, simply listen on channel 1 and advertise nothing, so
  /// they pair normally and then cannot be connected to by UUID at all.
  ///
  /// [uuid] is ignored when [channel] is given. Android only: the other
  /// platforms have no equivalent, and passing it there throws.
  ///
  /// Throws [BtcAddressException] if [address] is not a valid MAC.
  /// Throws [BtcUuidException] if [uuid] is not a valid UUID.
  /// Throws [BtcTimeoutException] if [timeout] elapses first.
  /// Throws [ArgumentError] if [channel] is outside 1-30.
  Future<BtcConnection> connect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    Duration? timeout,
    int? channel,
  }) {
    _validateAddress(address);
    if (channel == null) {
      _validateUuid(uuid);
    } else if (channel < 1 || channel > 30) {
      // Rejected here rather than at the socket, so the caller gets a clear
      // programming error instead of a connection failure to diagnose.
      throw ArgumentError.value(
        channel,
        'channel',
        'RFCOMM channel must be between 1 and 30',
      );
    }
    final future = _platform.connect(
      address: address,
      uuid: uuid,
      secure: secure,
      channel: channel,
    );
    if (timeout == null) return future;
    return future.timeout(
      timeout,
      onTimeout: () async {
        // `BluetoothSocket.connect()` has no timeout and no interrupt, so
        // giving up on the Dart side used to leave the native call blocked —
        // holding the device against every later attempt until the app was
        // restarted, and letting a late success register a connection Dart
        // could no longer close. Closing the socket is the only thing that
        // releases it.
        //
        // Failure to cancel is not worth surfacing over the timeout itself,
        // which is the more useful thing to tell the caller.
        try {
          await cancelConnect(address);
        } on Object {
          // Ignored deliberately; the timeout below is the real outcome.
        }
        throw BtcTimeoutException(
          message: 'Connection to $address timed out',
          timeoutMs: timeout.inMilliseconds,
        );
      },
    );
  }

  /// The Android API level this is running on, or null elsewhere.
  ///
  /// Exposed because which runtime permissions *exist* is a property of the OS
  /// version, and callers were reduced to inferring it from how a permission
  /// request behaved — which is guesswork, and has already been wrong once:
  /// `permission_handler` short-circuits a request for a permission the OS does
  /// not define by reporting it granted, so "granted" means both "the user
  /// agreed" and "there was nothing to agree to".
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Others | No — returns null |
  Future<int?> androidSdkInt() => _platform.androidSdkInt();

  /// Aborts an in-flight [connect] to [address].
  ///
  /// Returns true when a blocked attempt was found and released. Called
  /// automatically when [connect]'s own [timeout] expires; exposed because a
  /// caller running its own race may need it too.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Others | No — returns false |
  Future<bool> cancelConnect(String address) =>
      _platform.cancelConnect(address);

  /// Disconnects the connection with the given [id].
  ///
  /// Prefer using [BtcConnection.close] or [BtcConnection.finish]
  /// when you have a connection object. Use this when you only have the
  /// connection ID.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | Yes |
  Future<void> disconnect(int id) => _platform.disconnect(id);

  /// Connects to [address] and **automatically reconnects** if the link drops.
  ///
  /// Returns a [BtcReconnectingConnection] whose [BtcReconnectingConnection.input]
  /// and [BtcReconnectingConnection.state] streams are stable across reconnects.
  /// Subscribe once and keep receiving data as the underlying connection is
  /// transparently replaced. Retry timing is controlled by [policy]. Call
  /// [BtcReconnectingConnection.close] to stop.
  ///
  /// ```dart
  /// final link = bluetooth.connectWithReconnect(address: 'AA:BB:CC:DD:EE:FF');
  /// link.input.listen((bytes) => print('RX ${bytes.length}'));
  /// ```
  ///
  /// Available wherever [connect] is. Throws [BtcAddressException] /
  /// [BtcUuidException] for an invalid [address] / [uuid].
  BtcReconnectingConnection connectWithReconnect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    BtcReconnectPolicy policy = const BtcReconnectPolicy(),
  }) {
    _validateAddress(address);
    _validateUuid(uuid);
    final link = BtcReconnectingConnection(
      address: address,
      uuid: uuid,
      secure: secure,
      policy: policy,
      connector: () =>
          _platform.connect(address: address, uuid: uuid, secure: secure),
    );
    link.start();
    return link;
  }

  // ── Server ───────────────────────────────────────────────────────────

  /// Creates an RFCOMM server socket listening on the given [uuid].
  ///
  /// [uuid] defaults to [BtcUuid.spp] (the Serial Port Profile). [serviceName]
  /// is the SDP service name. If [secure] is `true`, uses
  /// authenticated/encrypted RFCOMM.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | No |
  ///
  /// Throws [BtcUuidException] if [uuid] is not a valid UUID.
  Future<BtcServerSocket> startServer({
    required String serviceName,
    String uuid = BtcUuid.spp,
    bool secure = true,
  }) {
    _validateUuid(uuid);
    return _platform.startServer(
        uuid: uuid, serviceName: serviceName, secure: secure);
  }

  // ── Discoverability ──────────────────────────────────────────────────

  /// Makes the local device discoverable for [durationSeconds].
  ///
  /// Returns `true` if the request was successful.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes (system dialog) |
  /// | Windows | Yes (BluetoothEnableDiscovery) |
  /// | macOS | No |
  /// | Linux | Yes |
  /// | iOS | No |
  Future<bool> setDiscoverable(int durationSeconds) =>
      _platform.setDiscoverable(durationSeconds);

  // ── Capabilities ─────────────────────────────────────────────────────

  /// Returns the platform capabilities for Bluetooth Classic.
  ///
  /// Use this to check what features are available before calling them.
  Future<BtcPlatformCapabilities> getPlatformCapabilities() =>
      _platform.getPlatformCapabilities();

  // ── Validation ───────────────────────────────────────────────────────

  void _validateAddress(String address) {
    if (Platform.isIOS) return;
    if (!_macAddressRegex.hasMatch(address)) {
      throw BtcAddressException(address);
    }
  }

  void _validateUuid(String uuid) {
    if (Platform.isIOS) return;
    if (!_uuidRegex.hasMatch(uuid)) {
      throw BtcUuidException(uuid);
    }
  }
}
