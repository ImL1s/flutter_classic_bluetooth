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
enum BluetoothAdapterState {
  unknown,
  turningOn,
  on,
  turningOff,
  off,
  unauthorized,
  unsupported,
}

/// Bond/pairing state of a Bluetooth device.
enum BluetoothBondState {
  none,
  bonding,
  bonded,
}

/// Type classification of a Bluetooth device.
enum BluetoothDeviceType {
  classic,
  dual,
  le,
  unknown,
}

/// Connection state of an active Bluetooth connection.
enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}
