import 'platform_interface.dart';
import 'models/btc_enums.dart';
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
  Future<List<BtcDevice>> getPairedDevices() =>
      _platform.getPairedDevices();

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
  /// If [secure] is `true` (default), uses authenticated/encrypted RFCOMM.
  /// Returns a [BtcConnection] for reading/writing data.
  ///
  /// If [timeout] is provided, the attempt fails with a [BtcTimeoutException]
  /// when it does not complete in time. Note: the native connection attempt may
  /// still resolve afterwards on some platforms; the returned connection (if
  /// any) is then orphaned — call [disconnect] if you track its id.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | Yes |
  /// | Windows | Yes |
  /// | macOS | Yes |
  /// | Linux | Yes |
  /// | iOS | ⚠️ (MFi accessories via protocol string) |
  ///
  /// Throws [BtcAddressException] if [address] is not a valid MAC.
  /// Throws [BtcUuidException] if [uuid] is not a valid UUID.
  /// Throws [BtcTimeoutException] if [timeout] elapses first.
  Future<BtcConnection> connect({
    required String address,
    required String uuid,
    bool secure = true,
    Duration? timeout,
  }) {
    _validateAddress(address);
    _validateUuid(uuid);
    final future =
        _platform.connect(address: address, uuid: uuid, secure: secure);
    if (timeout == null) return future;
    return future.timeout(
      timeout,
      onTimeout: () => throw BtcTimeoutException(
        message: 'Connection to $address timed out',
        timeoutMs: timeout.inMilliseconds,
      ),
    );
  }

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

  // ── Server ───────────────────────────────────────────────────────────

  /// Creates an RFCOMM server socket listening on the given [uuid].
  ///
  /// [serviceName] is the SDP service name. If [secure] is `true`,
  /// uses authenticated/encrypted RFCOMM.
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
    required String uuid,
    required String serviceName,
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
    if (!_macAddressRegex.hasMatch(address)) {
      throw BtcAddressException(address);
    }
  }

  void _validateUuid(String uuid) {
    if (!_uuidRegex.hasMatch(uuid)) {
      throw BtcUuidException(uuid);
    }
  }
}
