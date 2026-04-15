import 'platform_interface.dart';
import 'models/enums.dart';
import 'models/bluetooth_connection.dart';
import 'models/bluetooth_device.dart';
import 'models/bluetooth_server_socket.dart';
import 'models/platform_capabilities.dart';
import 'models/exceptions.dart';

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
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ✅ |
  Future<bool> isSupported() => _platform.isSupported();

  /// Returns whether the Bluetooth adapter is currently enabled.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ✅ |
  Future<bool> isEnabled() => _platform.isEnabled();

  /// Requests the system to enable the Bluetooth adapter.
  ///
  /// Returns `true` if Bluetooth was enabled or was already on.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ (system dialog) |
  /// | Windows | ❌ |
  /// | macOS | ❌ |
  /// | Linux | ✅ (rfkill) |
  /// | iOS | ❌ |
  Future<bool> enableBluetooth() => _platform.enableBluetooth();

  /// Requests the system to disable the Bluetooth adapter.
  ///
  /// Returns `true` if Bluetooth was disabled or was already off.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ (API < 33 only) |
  /// | Windows | ❌ |
  /// | macOS | ❌ |
  /// | Linux | ✅ (rfkill) |
  /// | iOS | ❌ |
  Future<bool> disableBluetooth() => _platform.disableBluetooth();

  /// Stream of adapter state changes.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ✅ |
  Stream<BluetoothAdapterState> get adapterState => _platform.adapterState();

  /// Returns the local adapter's friendly name.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  Future<String?> getAdapterName() => _platform.getAdapterName();

  /// Returns the local adapter's hardware address (MAC).
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ⚠️ (returns "02:00:00:00:00:00" on API 23+) |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  Future<String?> getAdapterAddress() => _platform.getAdapterAddress();

  // ── Discovery ────────────────────────────────────────────────────────

  /// Starts discovering nearby Bluetooth Classic devices.
  ///
  /// Listen to [discoveryResults] for found devices and [discoveryState]
  /// for discovery start/stop events.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  Future<void> startDiscovery() => _platform.startDiscovery();

  /// Stops an ongoing device discovery.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  Future<void> stopDiscovery() => _platform.stopDiscovery();

  /// Returns whether a discovery scan is currently in progress.
  Future<bool> isDiscovering() => _platform.isDiscovering();

  /// Stream that emits `true` when discovery starts and `false` when it stops.
  Stream<bool> get discoveryState => _platform.discoveryState();

  /// Stream of devices found during discovery.
  Stream<BluetoothDevice> get discoveryResults => _platform.discoveryResults();

  // ── Pairing ──────────────────────────────────────────────────────────

  /// Returns the list of currently paired/bonded devices.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ✅ (connected MFi accessories) |
  Future<List<BluetoothDevice>> getPairedDevices() =>
      _platform.getPairedDevices();

  /// Initiates pairing with the device at [address].
  ///
  /// Returns `true` if bonding succeeded.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ (system dialog) |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  ///
  /// Throws [BluetoothAddressException] if [address] is not a valid MAC.
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
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  ///
  /// Throws [BluetoothAddressException] if [address] is not a valid MAC.
  Future<bool> unbondDevice(String address) {
    _validateAddress(address);
    return _platform.unbondDevice(address);
  }

  /// Stream of bond state changes for a specific device.
  ///
  /// Throws [BluetoothAddressException] if [address] is not a valid MAC.
  Stream<BluetoothBondState> bondState(String address) {
    _validateAddress(address);
    return _platform.bondState(address);
  }

  // ── Connection ───────────────────────────────────────────────────────

  /// Connects to the device at [address] using the given [uuid].
  ///
  /// If [secure] is `true` (default), uses authenticated/encrypted RFCOMM.
  /// Returns a [BluetoothConnection] for reading/writing data.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ⚠️ (MFi accessories via protocol string) |
  ///
  /// Throws [BluetoothAddressException] if [address] is not a valid MAC.
  /// Throws [BluetoothUuidException] if [uuid] is not a valid UUID.
  Future<BluetoothConnection> connect({
    required String address,
    required String uuid,
    bool secure = true,
  }) {
    _validateAddress(address);
    _validateUuid(uuid);
    return _platform.connect(address: address, uuid: uuid, secure: secure);
  }

  /// Disconnects the connection with the given [id].
  ///
  /// Prefer using [BluetoothConnection.close] or [BluetoothConnection.finish]
  /// when you have a connection object. Use this when you only have the
  /// connection ID.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ✅ |
  Future<void> disconnect(int id) => _platform.disconnect(id);

  // ── Server ───────────────────────────────────────────────────────────

  /// Creates an RFCOMM server socket listening on the given [uuid].
  ///
  /// [serviceName] is the SDP service name. If [secure] is `true`,
  /// uses authenticated/encrypted RFCOMM.
  ///
  /// | Platform | Supported |
  /// |----------|-----------|
  /// | Android | ✅ |
  /// | Windows | ✅ |
  /// | macOS | ✅ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  ///
  /// Throws [BluetoothUuidException] if [uuid] is not a valid UUID.
  Future<BluetoothServerSocket> startServer({
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
  /// | Android | ✅ (system dialog) |
  /// | Windows | ❌ |
  /// | macOS | ❌ |
  /// | Linux | ✅ |
  /// | iOS | ❌ |
  Future<bool> setDiscoverable(int durationSeconds) =>
      _platform.setDiscoverable(durationSeconds);

  // ── Capabilities ─────────────────────────────────────────────────────

  /// Returns the platform capabilities for Bluetooth Classic.
  ///
  /// Use this to check what features are available before calling them.
  Future<PlatformCapabilities> getPlatformCapabilities() =>
      _platform.getPlatformCapabilities();

  // ── Validation ───────────────────────────────────────────────────────

  void _validateAddress(String address) {
    if (!_macAddressRegex.hasMatch(address)) {
      throw BluetoothAddressException(address);
    }
  }

  void _validateUuid(String uuid) {
    if (!_uuidRegex.hasMatch(uuid)) {
      throw BluetoothUuidException(uuid);
    }
  }
}
