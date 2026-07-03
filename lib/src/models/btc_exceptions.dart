/// Base exception for all Bluetooth Classic operations.
///
/// All plugin exceptions extend this class. Catch [BtcException]
/// to handle any Bluetooth error, or catch specific subclasses for
/// targeted error handling:
///
/// ```dart
/// try {
///   await bluetooth.startDiscovery();
/// } on BtcUnsupportedException catch (e) {
///   print('${e.feature} not supported on ${e.platform}');
/// } on BtcDisabledException {
///   print('Please enable Bluetooth');
/// } on BtcException catch (e) {
///   print('Error: ${e.message}');
/// }
/// ```
///
/// See also:
/// - [BtcUnsupportedException]: feature not available on platform
/// - [BtcPermissionException]: permission denied
/// - [BtcDisabledException]: adapter is off
/// - [BtcConnectionException]: connection failed
/// - [BtcWriteException]: write failed
/// - [BtcTimeoutException]: operation timed out
/// - [BtcAddressException]: invalid MAC address
/// - [BtcUuidException]: invalid UUID
///
/// {@category Exceptions}
class BtcException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional error code from the native platform.
  final String? code;

  /// Creates a [BtcException] with a [message] and optional [code].
  const BtcException(this.message, {this.code});

  @override
  String toString() => 'BtcException($code): $message';
}

/// Thrown when a feature is not available on the current platform.
///
/// For example, calling `startDiscovery()` on iOS throws this because
/// iOS does not support device discovery for Bluetooth Classic.
///
/// {@category Exceptions}
class BtcUnsupportedException extends BtcException {
  /// The feature that is not supported.
  final String feature;

  /// The platform where the feature is unsupported.
  final String platform;

  /// Creates an exception for [feature] on [platform], with an optional
  /// custom [reason] used as the message.
  const BtcUnsupportedException({
    required this.feature,
    required this.platform,
    String? reason,
  }) : super(
          reason ?? '$feature is not supported on $platform',
          code: 'unsupported',
        );

  @override
  String toString() =>
      'BtcUnsupportedException: $feature is not supported on $platform - $message';
}

/// Thrown when a required Bluetooth permission is denied.
///
/// {@category Exceptions}
class BtcPermissionException extends BtcException {
  /// Creates a [BtcPermissionException] with an optional [message].
  const BtcPermissionException([super.message = 'Bluetooth permission denied'])
      : super(code: 'permissionDenied');
}

/// Thrown when an operation requires Bluetooth to be enabled but it is off.
///
/// {@category Exceptions}
class BtcDisabledException extends BtcException {
  /// Creates a [BtcDisabledException] with an optional [message].
  const BtcDisabledException([super.message = 'Bluetooth adapter is disabled'])
      : super(code: 'bluetoothDisabled');
}

/// Thrown when a connection attempt fails.
///
/// {@category Exceptions}
class BtcConnectionException extends BtcException {
  /// The address of the device that failed to connect.
  final String? address;

  /// Creates a [BtcConnectionException] with a [message] and optional [address].
  const BtcConnectionException(
    super.message, {
    this.address,
  }) : super(code: 'connectionFailed');
}

/// Thrown when a write operation to a connected device fails.
///
/// {@category Exceptions}
class BtcWriteException extends BtcException {
  /// Creates a [BtcWriteException] with an optional [message].
  const BtcWriteException([super.message = 'Failed to write data'])
      : super(code: 'writeFailed');
}

/// Thrown when an operation times out.
///
/// {@category Exceptions}
class BtcTimeoutException extends BtcException {
  /// The duration in milliseconds that elapsed before timeout.
  final int? timeoutMs;

  /// Creates a [BtcTimeoutException] with an optional [message] and the
  /// elapsed [timeoutMs].
  const BtcTimeoutException({
    String message = 'Operation timed out',
    this.timeoutMs,
  }) : super(message, code: 'timeout');
}

/// Thrown when starting or running device discovery fails.
///
/// {@category Exceptions}
class BtcDiscoveryException extends BtcException {
  /// Creates a [BtcDiscoveryException] with an optional [message].
  const BtcDiscoveryException([super.message = 'Failed to start discovery'])
      : super(code: 'discoveryFailed');
}

/// Thrown when an invalid Bluetooth MAC address is provided.
///
/// {@category Exceptions}
class BtcAddressException extends BtcException {
  /// The invalid address that was provided.
  final String address;

  /// Creates a [BtcAddressException] for the invalid [address].
  const BtcAddressException(this.address)
      : super('Invalid Bluetooth address: $address', code: 'invalidAddress');
}

/// Thrown when an invalid UUID is provided.
///
/// {@category Exceptions}
class BtcUuidException extends BtcException {
  /// The invalid UUID that was provided.
  final String uuid;

  /// Creates a [BtcUuidException] for the invalid [uuid].
  const BtcUuidException(this.uuid)
      : super('Invalid UUID: $uuid', code: 'invalidUuid');
}
