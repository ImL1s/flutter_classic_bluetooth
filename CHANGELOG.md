## 0.1.0

* Initial release.
* Unified Dart API for Bluetooth Classic (RFCOMM) communication.
* **Android**: Full support — discovery, pairing, connect, server, discoverability.
* **Windows**: Discovery, pairing, connect, server via Winsock2/AF_BTH.
* **macOS**: Discovery, pairing, connect, server via IOBluetooth.
* **Linux**: Discovery, connect, server via BlueZ/RFCOMM. Pairing requires external tools.
* **iOS**: MFi accessory support via ExternalAccessory framework.
* Platform capabilities API for runtime feature detection.
* Multiple simultaneous RFCOMM connections.
* Stream-based data I/O with `BtcConnection`.
* Typed exception hierarchy (`BtcException` and subtypes).
* Example app with 7 screens demonstrating all features.
