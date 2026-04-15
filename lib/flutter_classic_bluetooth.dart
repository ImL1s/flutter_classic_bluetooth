/// Flutter Classic Bluetooth — Bluetooth Classic (RFCOMM) communication plugin.
///
/// Provides a unified Dart API for discovering, pairing, and communicating
/// with Bluetooth Classic devices over RFCOMM across Android, iOS (MFi only),
/// Windows, macOS, and Linux.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
///
/// final bluetooth = FlutterClassicBluetooth();
/// ```
///
/// ## Core API
///
/// | Class | Purpose |
/// |---|---|
/// | [FlutterClassicBluetooth] | Main entry point — adapter, discovery, pairing, connection, server |
/// | [BluetoothDevice] | Represents a remote Bluetooth device |
/// | [BluetoothConnection] | Active RFCOMM connection with input/output streams |
/// | [BluetoothServerSocket] | Listens for incoming RFCOMM connections |
/// | [BluetoothStreamSink] | Ordered write sink for a connection |
/// | [PlatformCapabilities] | Platform feature support matrix |
///
/// ## Enums
///
/// | Enum | Purpose |
/// |---|---|
/// | [BluetoothAdapterState] | Adapter on/off/transitioning states |
/// | [BluetoothBondState] | Device pairing state |
/// | [BluetoothDeviceType] | Classic, LE, or Dual-mode |
/// | [BluetoothConnectionState] | Connection lifecycle states |
///
/// ## Exceptions
///
/// All exceptions extend [BluetoothException]:
///
/// | Exception | When |
/// |---|---|
/// | [BluetoothUnsupportedException] | Feature not available on platform |
/// | [BluetoothPermissionException] | Permission denied |
/// | [BluetoothDisabledException] | Adapter is off |
/// | [BluetoothConnectionException] | Connection failed |
/// | [BluetoothWriteException] | Write failed |
/// | [BluetoothTimeoutException] | Operation timed out |
/// | [BluetoothAddressException] | Invalid MAC address |
/// | [BluetoothUuidException] | Invalid UUID |
///
/// ## Platform Support
///
/// | Feature | Android | iOS | Windows | macOS | Linux |
/// |---------|---------|-----|---------|-------|-------|
/// | Adapter state | ✅ | ✅ | ✅ | ✅ | ✅ |
/// | Discovery | ✅ | ❌ | ✅ | ✅ | ✅ |
/// | Paired devices | ✅ | ✅¹ | ✅ | ✅ | ✅ |
/// | Bond/Unbond | ✅ | ❌ | ✅ | ✅ | ❌² |
/// | RFCOMM connect | ✅ | ✅¹ | ✅ | ✅ | ✅ |
/// | RFCOMM server | ✅ | ❌ | ✅ | ✅ | ✅ |
/// | Enable/Disable | ✅ | ❌ | ❌ | ❌ | ✅ |
/// | Set discoverable | ✅ | ❌ | ❌ | ❌ | ✅ |
///
/// ¹ iOS requires MFi-certified accessories via ExternalAccessory framework.
/// ² Linux returns an error for bond/unbond operations.
///
/// ## Example
///
/// ```dart
/// // Discover and connect
/// final caps = await bluetooth.getPlatformCapabilities();
/// if (caps.canDiscoverDevices) {
///   bluetooth.discoveryResults.listen((device) {
///     print('Found: ${device.displayName}');
///   });
///   await bluetooth.startDiscovery();
/// }
///
/// // Connect to a device
/// final conn = await bluetooth.connect(
///   address: 'AA:BB:CC:DD:EE:FF',
///   uuid: '00001101-0000-1000-8000-00805F9B34FB',
/// );
/// conn.input.listen((data) => print('Received: $data'));
/// await conn.output.add(Uint8List.fromList([0x01, 0x02]));
/// await conn.finish();
/// ```
library;

export 'src/flutter_classic_bluetooth.dart';
export 'src/platform_interface.dart';
export 'src/method_channel.dart';
export 'src/models/enums.dart';
export 'src/models/exceptions.dart';
export 'src/models/bluetooth_device.dart';
export 'src/models/bluetooth_connection.dart';
export 'src/models/bluetooth_stream_sink.dart';
export 'src/models/bluetooth_server_socket.dart';
export 'src/models/platform_capabilities.dart';
