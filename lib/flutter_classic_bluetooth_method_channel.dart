import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_classic_bluetooth_platform_interface.dart';

/// An implementation of [FlutterClassicBluetoothPlatform] that uses method channels.
class MethodChannelFlutterClassicBluetooth extends FlutterClassicBluetoothPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_classic_bluetooth');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
