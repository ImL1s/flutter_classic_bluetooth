import Flutter
import UIKit
import ExternalAccessory
import CoreBluetooth

public class FlutterClassicBluetoothPlugin: NSObject, FlutterPlugin {
    private var messenger: FlutterBinaryMessenger!
    private var connections: [Int: EASessionWrapper] = [:]
    private var nextConnectionId = 0
    private let adapterStateHandler = AdapterStateStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_classic_bluetooth/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterClassicBluetoothPlugin()
        instance.messenger = registrar.messenger()

        // Adapter state via CoreBluetooth (radio power state).
        let adapterChannel = FlutterEventChannel(
            name: "flutter_classic_bluetooth/adapter_state",
            binaryMessenger: registrar.messenger()
        )
        adapterChannel.setStreamHandler(instance.adapterStateHandler)

        registrar.addMethodCallDelegate(instance, channel: channel)

        EAAccessoryManager.shared().registerForLocalNotifications()
        NotificationCenter.default.addObserver(
            instance,
            selector: #selector(accessoryDidDisconnect(_:)),
            name: .EAAccessoryDidDisconnect,
            object: nil
        )
    }

    @objc private func accessoryDidDisconnect(_ notification: Notification) {
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
            return
        }
        for (id, wrapper) in connections {
            if wrapper.accessoryConnectionID == accessory.connectionID {
                wrapper.close()
                connections.removeValue(forKey: id)

                break
            }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "isSupported":
            // iOS supports Bluetooth Classic only for MFi accessories
            result(true)

        case "isEnabled":
            // Prefer the CoreBluetooth radio state once it is known; fall back to
            // the ExternalAccessory heuristic (a connected accessory implies on)
            // until the first state callback arrives.
            adapterStateHandler.ensureManager()
            if let on = adapterStateHandler.isPoweredOn {
                result(on)
            } else {
                result(!EAAccessoryManager.shared().connectedAccessories.isEmpty)
            }

        case "enableBluetooth", "disableBluetooth":
            result(FlutterError(
                code: "unsupported",
                message: "Cannot programmatically \(call.method == "enableBluetooth" ? "enable" : "disable") Bluetooth on iOS",
                details: ["feature": call.method, "platform": "iOS"]
            ))

        case "getAdapterName":
            result(UIDevice.current.name)

        case "getAdapterAddress":
            // iOS does not expose the Bluetooth adapter address
            result(nil)

        case "startDiscovery":
            result(FlutterError(
                code: "unsupported",
                message: "Device discovery not available on iOS. Only MFi accessories visible via getPairedDevices.",
                details: ["feature": "startDiscovery", "platform": "iOS"]
            ))

        case "stopDiscovery":
            result(FlutterError(
                code: "unsupported",
                message: "Device discovery not available on iOS",
                details: ["feature": "stopDiscovery", "platform": "iOS"]
            ))

        case "isDiscovering":
            result(false)

        case "getPairedDevices":
            handleGetPairedDevices(result: result)

        case "bondDevice":
            result(FlutterError(
                code: "unsupported",
                message: "Bonding not available on iOS. Pair through iOS Settings.",
                details: ["feature": "bondDevice", "platform": "iOS"]
            ))

        case "unbondDevice":
            result(FlutterError(
                code: "unsupported",
                message: "Unbonding not available on iOS. Unpair through iOS Settings.",
                details: ["feature": "unbondDevice", "platform": "iOS"]
            ))

        case "connect":
            // iOS MFi: accept either "protocol" (preferred) or fall back to "uuid"
            let protocolString = args?["protocol"] as? String ?? args?["uuid"] as? String
            guard let proto = protocolString else {
                result(FlutterError(
                    code: "connectionFailed",
                    message: "Protocol string (or uuid) is required for iOS MFi connection. On iOS, the uuid parameter is used as the MFi protocol string.",
                    details: ["feature": "connect", "platform": "iOS"]
                ))
                return
            }
            handleConnect(protocolString: proto, result: result)

        case "disconnect":
            guard let id = args?["id"] as? Int else {
                result(FlutterError(code: "connectionFailed", message: "Connection ID is required", details: nil))
                return
            }
            handleDisconnect(id: id, result: result)

        case "write":
            guard let id = args?["id"] as? Int,
                  let data = args?["data"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "writeFailed", message: "Connection ID and data are required", details: nil))
                return
            }
            handleWrite(id: id, data: data, result: result)

        case "startServer":
            result(FlutterError(
                code: "unsupported",
                message: "Server mode not available on iOS",
                details: ["feature": "startServer", "platform": "iOS"]
            ))

        case "stopServer":
            result(FlutterError(
                code: "unsupported",
                message: "Server mode not available on iOS",
                details: ["feature": "stopServer", "platform": "iOS"]
            ))

        case "setDiscoverable":
            result(FlutterError(
                code: "unsupported",
                message: "setDiscoverable not available on iOS",
                details: ["feature": "setDiscoverable", "platform": "iOS"]
            ))

        case "getPlatformCapabilities":
            handleGetPlatformCapabilities(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Paired Devices (Connected MFi Accessories)

    private func handleGetPairedDevices(result: @escaping FlutterResult) {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        let devices = accessories.map { accessory -> [String: Any?] in
            return [
                "address": String(accessory.connectionID),
                "name": accessory.name,
                "alias": accessory.manufacturer,
                "type": "unknown",
                "bondState": "bonded",
                // Documented as the accessory's MFi protocol strings.
                "uuids": accessory.protocolStrings,
                "isConnected": accessory.isConnected
            ]
        }
        result(devices)
    }

    // MARK: - Connection

    private func handleConnect(protocolString: String, result: @escaping FlutterResult) {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        guard let accessory = accessories.first(where: { $0.protocolStrings.contains(protocolString) }) else {
            result(FlutterError(
                code: "connectionFailed",
                message: "No MFi accessory found with protocol: \(protocolString)",
                details: ["protocol": protocolString]
            ))
            return
        }

        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else {
            result(FlutterError(
                code: "connectionFailed",
                message: "Failed to create session for accessory",
                details: ["protocol": protocolString]
            ))
            return
        }

        let connId = nextConnectionId
        nextConnectionId += 1

        let wrapper = EASessionWrapper(id: connId, session: session, accessoryConnectionID: accessory.connectionID, messenger: messenger)
        wrapper.startReading()
        connections[connId] = wrapper

        result([
            "id": connId,
            "address": String(accessory.connectionID)
        ])
    }

    private func handleDisconnect(id: Int, result: @escaping FlutterResult) {
        if let conn = connections.removeValue(forKey: id) {
            conn.close()
        }
        result(nil)
    }

    private func handleWrite(id: Int, data: FlutterStandardTypedData, result: @escaping FlutterResult) {
        guard let conn = connections[id] else {
            result(FlutterError(code: "connectionFailed", message: "Connection not found", details: nil))
            return
        }
        if conn.write(data: data.data) {
            result(nil)
        } else {
            result(FlutterError(code: "writeFailed", message: "Failed to write data", details: nil))
        }
    }

    // MARK: - Capabilities

    private func handleGetPlatformCapabilities(result: @escaping FlutterResult) {
        result([
            "canEnableBluetooth": false,
            "canDisableBluetooth": false,
            "canDiscoverDevices": false,
            "canGetPairedDevices": true,
            "canBondDevices": false,
            "canUnbondDevices": false,
            "canCreateServer": false,
            "canSetDiscoverable": false,
            "supportsMultipleConnections": true,
            "supportsSecureConnection": true,
            "supportsInsecureConnection": false,
            "requiresMfiCertification": true,
            "platformNote": "iOS: Bluetooth Classic via ExternalAccessory. Only MFi-certified accessories supported. Discovery, pairing, and server mode not available. Pair through iOS Settings."
        ])
    }
}

// MARK: - EASession Wrapper

class EASessionWrapper: NSObject, StreamDelegate {
    let id: Int
    let accessoryConnectionID: Int
    private let session: EASession
    private var messenger: FlutterBinaryMessenger
    private var dataStreamHandler: IOSStreamHandler?
    private var stateStreamHandler: IOSStreamHandler?

    init(id: Int, session: EASession, accessoryConnectionID: Int, messenger: FlutterBinaryMessenger) {
        self.id = id
        self.accessoryConnectionID = accessoryConnectionID
        self.session = session
        self.messenger = messenger
        super.init()
        setupEventChannels()
    }

    private func setupEventChannels() {
        let dataHandler = IOSStreamHandler()
        dataStreamHandler = dataHandler
        let dataChannel = FlutterEventChannel(
            name: "flutter_classic_bluetooth/connection/\(id)",
            binaryMessenger: messenger
        )
        dataChannel.setStreamHandler(dataHandler)

        let stateHandler = IOSStreamHandler()
        stateStreamHandler = stateHandler
        let stateChannel = FlutterEventChannel(
            name: "flutter_classic_bluetooth/connection_state/\(id)",
            binaryMessenger: messenger
        )
        stateChannel.setStreamHandler(stateHandler)
    }

    func startReading() {
        guard let inputStream = session.inputStream else { return }
        inputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .default)
        inputStream.open()

        session.outputStream?.schedule(in: .current, forMode: .default)
        session.outputStream?.open()

        stateStreamHandler?.eventSink?("connected")
    }

    func write(data: Data) -> Bool {
        guard let outputStream = session.outputStream else { return false }
        let bytes = [UInt8](data)
        let written = outputStream.write(bytes, maxLength: bytes.count)
        return written == bytes.count
    }

    func close() {
        session.inputStream?.close()
        session.inputStream?.remove(from: .current, forMode: .default)
        session.outputStream?.close()
        session.outputStream?.remove(from: .current, forMode: .default)
        stateStreamHandler?.eventSink?("disconnected")
    }

    // StreamDelegate
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            guard let inputStream = aStream as? InputStream else { return }
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                let data = Data(buffer[0..<bytesRead])
                dataStreamHandler?.eventSink?(FlutterStandardTypedData(bytes: data))
            }
        case .errorOccurred:
            stateStreamHandler?.eventSink?("disconnected")
        case .endEncountered:
            stateStreamHandler?.eventSink?("disconnected")
        default:
            break
        }
    }
}

// MARK: - Stream Handler

private class IOSStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - Adapter State (CoreBluetooth)

/// Bridges CoreBluetooth's central-manager power state to the adapter_state
/// event channel. The manager is created lazily so the Bluetooth permission
/// prompt only appears when the app actually queries adapter state.
private class AdapterStateStreamHandler: NSObject, FlutterStreamHandler, CBCentralManagerDelegate {
    private var eventSink: FlutterEventSink?
    private var centralManager: CBCentralManager?
    private var lastState: CBManagerState = .unknown

    func ensureManager() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    /// `nil` until CoreBluetooth reports a definitive state.
    var isPoweredOn: Bool? {
        switch lastState {
        case .unknown, .resetting: return nil
        case .poweredOn: return true
        default: return false
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        ensureManager()
        if lastState != .unknown {
            events(AdapterStateStreamHandler.stateString(lastState))
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        lastState = central.state
        eventSink?(AdapterStateStreamHandler.stateString(central.state))
    }

    static func stateString(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "on"
        case .poweredOff: return "off"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        case .resetting: return "turningOn"
        default: return "unknown"
        }
    }
}
