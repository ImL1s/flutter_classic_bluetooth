/// State of the Bluetooth adapter.
///
/// | State | Description |
/// |-------|-------------|
/// | unknown | Adapter state cannot be determined |
/// | turningOn | Adapter is transitioning to the on state |
/// | on | Adapter is powered on and ready |
/// | turningOff | Adapter is transitioning to the off state |
/// | off | Adapter is powered off |
/// | unauthorized | App lacks permission to access Bluetooth |
/// | unsupported | Device does not have Bluetooth hardware |
///
/// {@category Enums}
enum BluetoothAdapterState {
  /// Adapter state cannot be determined.
  unknown,

  /// Adapter is transitioning to the on state.
  turningOn,

  /// Adapter is powered on and ready.
  on,

  /// Adapter is transitioning to the off state.
  turningOff,

  /// Adapter is powered off.
  off,

  /// App lacks permission to access Bluetooth.
  unauthorized,

  /// Device does not have Bluetooth hardware.
  unsupported,
}

/// Bond/pairing state of a remote Bluetooth device.
///
/// | State | Description |
/// |-------|-------------|
/// | none | Not bonded with this device |
/// | bonding | Pairing is in progress |
/// | bonded | Device is bonded/paired |
///
/// {@category Enums}
enum BluetoothBondState {
  /// Not bonded with this device.
  none,

  /// Pairing is in progress.
  bonding,

  /// Device is bonded/paired.
  bonded,
}

/// Type classification of a Bluetooth device.
///
/// | Type | Description |
/// |------|-------------|
/// | classic | Bluetooth Classic (BR/EDR) device |
/// | dual | Dual-mode device supporting both Classic and LE |
/// | le | Bluetooth Low Energy only device |
/// | unknown | Device type could not be determined |
///
/// {@category Enums}
enum BluetoothDeviceType {
  /// Bluetooth Classic (BR/EDR) device.
  classic,

  /// Dual-mode device supporting both Classic and LE.
  dual,

  /// Bluetooth Low Energy only device.
  le,

  /// Device type could not be determined.
  unknown,
}

/// Connection state of an active RFCOMM connection.
///
/// | State | Description |
/// |-------|-------------|
/// | disconnected | No active connection |
/// | connecting | Connection attempt in progress |
/// | connected | Connection is active and ready |
/// | disconnecting | Graceful disconnect in progress |
///
/// {@category Enums}
enum BluetoothConnectionState {
  /// No active connection.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Connection is active and ready for I/O.
  connected,

  /// Graceful disconnect in progress.
  disconnecting,
}
