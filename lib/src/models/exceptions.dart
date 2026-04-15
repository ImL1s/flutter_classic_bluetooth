/// Base exception for all Bluetooth Classic operations.
class BluetoothException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional error code from the native platform.
  final String? code;

  const BluetoothException(this.message, {this.code});

  @override
  String toString() => 'BluetoothException($code): $message';
}

/// Thrown when a feature is not available on the current platform.
///
/// For example, calling [startDiscovery] on iOS throws this because
/// iOS does not support device discovery for Bluetooth Classic.
class BluetoothUnsupportedException extends BluetoothException {
  /// The feature that is not supported.
  final String feature;

  /// The platform where the feature is unsupported.
  final String platform;

  const BluetoothUnsupportedException({
    required this.feature,
    required this.platform,
    String? reason,
  }) : super(
          reason ??
              '$feature is not supported on $platform',
          code: 'unsupported',
        );

  @override
  String toString() =>
      'BluetoothUnsupportedException: $feature is not supported on $platform — $message';
}

/// Thrown when a required Bluetooth permission is denied.
class BluetoothPermissionException extends BluetoothException {
  const BluetoothPermissionException([super.message = 'Bluetooth permission denied'])
      : super(code: 'permissionDenied');
}

/// Thrown when an operation requires Bluetooth to be enabled but it is off.
class BluetoothDisabledException extends BluetoothException {
  const BluetoothDisabledException(
      [super.message = 'Bluetooth adapter is disabled'])
      : super(code: 'bluetoothDisabled');
}

/// Thrown when a connection attempt fails.
class BluetoothConnectionException extends BluetoothException {
  /// The address of the device that failed to connect.
  final String? address;

  const BluetoothConnectionException(
    super.message, {
    this.address,
  }) : super(code: 'connectionFailed');
}

/// Thrown when a write operation to a connected device fails.
class BluetoothWriteException extends BluetoothException {
  const BluetoothWriteException([super.message = 'Failed to write data'])
      : super(code: 'writeFailed');
}

/// Thrown when an operation times out.
class BluetoothTimeoutException extends BluetoothException {
  /// The duration in milliseconds that elapsed before timeout.
  final int? timeoutMs;

  const BluetoothTimeoutException({
    String message = 'Operation timed out',
    this.timeoutMs,
  }) : super(message, code: 'timeout');
}

/// Thrown when an invalid Bluetooth MAC address is provided.
class BluetoothAddressException extends BluetoothException {
  /// The invalid address that was provided.
  final String address;

  const BluetoothAddressException(this.address)
      : super('Invalid Bluetooth address: $address', code: 'invalidAddress');
}

/// Thrown when an invalid UUID is provided.
class BluetoothUuidException extends BluetoothException {
  /// The invalid UUID that was provided.
  final String uuid;

  const BluetoothUuidException(this.uuid)
      : super('Invalid UUID: $uuid', code: 'invalidUuid');
}
