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
/// | [BtcDevice] | Represents a remote Bluetooth device |
/// | [BtcConnection] | Active RFCOMM connection with input/output streams |
/// | [BtcServerSocket] | Listens for incoming RFCOMM connections |
/// | [BtcStreamSink] | Ordered write sink for a connection |
/// | [BtcPlatformCapabilities] | Platform feature support matrix |
///
/// ## Enums
///
/// | Enum | Purpose |
/// |---|---|
/// | [BtcAdapterState] | Adapter on/off/transitioning states |
/// | [BtcBondState] | Device pairing state |
/// | [BtcDeviceType] | Classic, LE, or Dual-mode |
/// | [BtcConnectionState] | Connection lifecycle states |
///
/// ## Exceptions
///
/// All exceptions extend [BtcException]:
///
/// | Exception | When |
/// |---|---|
/// | [BtcUnsupportedException] | Feature not available on platform |
/// | [BtcPermissionException] | Permission denied |
/// | [BtcDisabledException] | Adapter is off |
/// | [BtcConnectionException] | Connection failed |
/// | [BtcWriteException] | Write failed |
/// | [BtcDiscoveryException] | Discovery failed to start |
/// | [BtcTimeoutException] | Operation timed out |
/// | [BtcAddressException] | Invalid MAC address |
/// | [BtcUuidException] | Invalid UUID |
///
/// ## Platform Support
///
/// | Feature | Android | iOS | Windows | macOS | Linux |
/// |---------|---------|-----|---------|-------|-------|
/// | Adapter state | Yes | Yes | Yes | Yes | Yes |
/// | Discovery | Yes | No | Yes | Yes | Yes |
/// | Paired devices | Yes | Yes(1) | Yes | Yes | No(3) |
/// | Bond/Unbond | Yes | No | Yes | No(2) | No(2) |
/// | RFCOMM connect | Yes | Yes(1) | Yes | Yes | Yes |
/// | RFCOMM server | Yes | No | Yes | Yes | Yes |
/// | Enable/Disable | Yes | No | No | No | No |
/// | Set discoverable | Yes | No | No | No | Yes |
///
/// (1) iOS requires MFi-certified accessories via ExternalAccessory framework.
/// (2) macOS/Linux pairing is done through the OS (System Settings / `bluetoothctl`).
/// (3) Linux paired-device listing requires the BlueZ D-Bus API.
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
export 'src/models/btc_enums.dart';
export 'src/models/btc_exceptions.dart';
export 'src/models/btc_device.dart';
export 'src/models/btc_connection.dart';
export 'src/models/btc_stream_sink.dart';
export 'src/models/btc_server_socket.dart';
export 'src/models/btc_platform_capabilities.dart';
