import 'enums.dart';

/// Represents a Bluetooth Classic remote device.
///
/// Contains device information obtained from discovery or paired device queries.
///
/// | Property | Android | Windows | macOS | Linux | iOS |
/// |----------|---------|---------|-------|-------|-----|
/// | address | ✅ MAC | ✅ MAC | ✅ MAC | ✅ MAC | ⚠️ serial/ID |
/// | name | ✅ | ✅ | ✅ | ✅ | ✅ |
/// | alias | ✅ API 30+ | ❌ | ❌ | ✅ | ❌ |
/// | rssi | ✅ | ❌ | ✅ | ✅ | ❌ |
/// | type | ✅ | ❌ | ❌ | ❌ | ❌ |
/// | bondState | ✅ | ✅ | ✅ | ✅ | ✅ (always bonded) |
/// | uuids | ✅ | ✅ | ✅ | ✅ | ⚠️ protocol strings |
///
/// {@category Models}
class BluetoothDevice {
  /// The hardware address of the device.
  ///
  /// On most platforms this is the MAC address (e.g. `"AA:BB:CC:DD:EE:FF"`).
  /// On iOS this is the accessory serial number or connection ID string.
  final String address;

  /// The broadcasted friendly name of the device, or null if unknown.
  final String? name;

  /// The locally set alias name, if available.
  ///
  /// Only available on Android (API 30+) and Linux.
  final String? alias;

  /// Signal strength in dBm, reported during discovery.
  ///
  /// Null if not available or not discovered via scan.
  final int? rssi;

  /// The type of Bluetooth device.
  final BluetoothDeviceType type;

  /// The current bond/pairing state.
  final BluetoothBondState bondState;

  /// Service UUIDs advertised by the device.
  ///
  /// On iOS these are MFi protocol strings.
  final List<String> uuids;

  const BluetoothDevice({
    required this.address,
    this.name,
    this.alias,
    this.rssi,
    this.type = BluetoothDeviceType.unknown,
    this.bondState = BluetoothBondState.none,
    this.uuids = const [],
  });

  /// Creates a [BluetoothDevice] from a platform channel map.
  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      address: map['address'] as String,
      name: map['name'] as String?,
      alias: map['alias'] as String?,
      rssi: map['rssi'] as int?,
      type: BluetoothDeviceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BluetoothDeviceType.unknown,
      ),
      bondState: BluetoothBondState.values.firstWhere(
        (e) => e.name == map['bondState'],
        orElse: () => BluetoothBondState.none,
      ),
      uuids: List<String>.from(map['uuids'] ?? []),
    );
  }

  /// Converts this device to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'name': name,
      'alias': alias,
      'rssi': rssi,
      'type': type.name,
      'bondState': bondState.name,
      'uuids': uuids,
    };
  }

  /// Returns the best available display name for this device.
  String get displayName => alias ?? name ?? address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() =>
      'BluetoothDevice(address: $address, name: $name, bondState: $bondState)';
}
