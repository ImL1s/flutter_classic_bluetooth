import 'dart:async';

import 'package:flutter/services.dart';

/// A write sink for an active Bluetooth connection.
///
/// Writes are queued and delivered in order using chained futures,
/// ensuring that data is sent sequentially even if [add] is called
/// multiple times without awaiting.
///
/// ```dart
/// final sink = connection.output;
/// await sink.add(Uint8List.fromList([0x01, 0x02]));
/// await sink.add(utf8.encode('Hello'));
/// await sink.close(); // waits for all pending writes
/// ```
class BluetoothStreamSink {
  final int connectionId;
  final MethodChannel _methodChannel;
  Future<void> _lastWrite = Future.value();
  bool _closed = false;

  /// Creates a [BluetoothStreamSink] for the given [connectionId].
  BluetoothStreamSink({
    required this.connectionId,
    required MethodChannel methodChannel,
  }) : _methodChannel = methodChannel;

  /// Whether this sink has been closed.
  bool get isClosed => _closed;

  /// Queues [data] to be written to the remote device.
  ///
  /// Writes are chained so they execute in the order they are added.
  /// The returned future completes when this particular write finishes.
  /// Throws [StateError] if the sink has been closed.
  Future<void> add(Uint8List data) {
    if (_closed) {
      throw StateError('Cannot write to a closed BluetoothStreamSink');
    }

    _lastWrite = _lastWrite.then((_) {
      return _methodChannel.invokeMethod('write', {
        'id': connectionId,
        'data': data,
      });
    });

    return _lastWrite;
  }

  /// Waits for all pending writes to complete, then marks this sink as closed.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _lastWrite;
  }

  /// Immediately marks the sink as closed without waiting for pending writes.
  void cancel() {
    _closed = true;
  }
}
