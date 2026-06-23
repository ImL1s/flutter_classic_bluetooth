import Cocoa
import FlutterMacOS
import IOBluetooth

public class FlutterClassicBluetoothPlugin: NSObject, FlutterPlugin {
    private var messenger: FlutterBinaryMessenger!
    private var connections: [Int: BluetoothConnectionWrapper] = [:]
    private var servers: [Int: BluetoothServerWrapper] = [:]
    private var nextConnectionId = 0
    private var nextServerId = 0
    private var inquiryDelegate: DeviceInquiryDelegate?
    private var discovering = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_classic_bluetooth/methods",
            binaryMessenger: registrar.messenger
        )
        let instance = FlutterClassicBluetoothPlugin()
        instance.messenger = registrar.messenger
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "isSupported":
            result(IOBluetoothHostController.default() != nil)

        case "isEnabled":
            if let controller = IOBluetoothHostController.default() {
                result(controller.powerState == kBluetoothHCIPowerStateON)
            } else {
                result(false)
            }

        case "enableBluetooth", "disableBluetooth":
            result(FlutterError(
                code: "unsupported",
                message: "Cannot programmatically \(call.method == "enableBluetooth" ? "enable" : "disable") Bluetooth on macOS",
                details: ["feature": call.method, "platform": "macOS"]
            ))

        case "getAdapterName":
            result(IOBluetoothHostController.default()?.nameAsString())

        case "getAdapterAddress":
            result(IOBluetoothHostController.default()?.addressAsString()?.replacingOccurrences(of: "-", with: ":").uppercased())

        case "startDiscovery":
            handleStartDiscovery(result: result)

        case "stopDiscovery":
            handleStopDiscovery(result: result)

        case "isDiscovering":
            result(discovering)

        case "getPairedDevices":
            handleGetPairedDevices(result: result)

        case "bondDevice":
            guard let address = args?["address"] as? String else {
                result(FlutterError(code: "invalidAddress", message: "Address is required", details: nil))
                return
            }
            handleBondDevice(address: address, result: result)

        case "unbondDevice":
            guard let address = args?["address"] as? String else {
                result(FlutterError(code: "invalidAddress", message: "Address is required", details: nil))
                return
            }
            handleUnbondDevice(address: address, result: result)

        case "connect":
            guard let address = args?["address"] as? String else {
                result(FlutterError(code: "connectionFailed", message: "Address is required", details: nil))
                return
            }
            let uuid = args?["uuid"] as? String ?? "00001101-0000-1000-8000-00805F9B34FB"
            handleConnect(address: address, uuid: uuid, result: result)

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
            let uuid = args?["uuid"] as? String ?? "00001101-0000-1000-8000-00805F9B34FB"
            let serviceName = args?["serviceName"] as? String ?? "FlutterBluetooth"
            handleStartServer(uuid: uuid, serviceName: serviceName, result: result)

        case "stopServer":
            guard let id = args?["id"] as? Int else {
                result(FlutterError(code: "connectionFailed", message: "Server ID is required", details: nil))
                return
            }
            handleStopServer(id: id, result: result)

        case "setDiscoverable":
            result(FlutterError(
                code: "unsupported",
                message: "setDiscoverable not available on macOS",
                details: ["feature": "setDiscoverable", "platform": "macOS"]
            ))

        case "getPlatformCapabilities":
            handleGetPlatformCapabilities(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Discovery

    private func handleStartDiscovery(result: @escaping FlutterResult) {
        if discovering {
            result(nil)
            return
        }
        discovering = true
        let inquiry = IOBluetoothDeviceInquiry(delegate: nil)
        let delegate = DeviceInquiryDelegate { [weak self] in
            self?.discovering = false
        }
        inquiry?.delegate = delegate
        inquiryDelegate = delegate
        inquiry?.start()
        result(nil)
    }

    private func handleStopDiscovery(result: @escaping FlutterResult) {
        discovering = false
        result(nil)
    }

    // MARK: - Paired Devices

    private func handleGetPairedDevices(result: @escaping FlutterResult) {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        let devices = paired.map { deviceToMap($0) }
        result(devices)
    }

    // MARK: - Bonding

    private func handleBondDevice(address: String, result: @escaping FlutterResult) {
        guard let device = IOBluetoothDevice(addressString: address) else {
            result(false)
            return
        }
        let ret = device.requestConnection()
        result(ret == kIOReturnSuccess)
    }

    private func handleUnbondDevice(address: String, result: @escaping FlutterResult) {
        guard let device = IOBluetoothDevice(addressString: address) else {
            result(false)
            return
        }
        device.closeConnection()
        result(true)
    }

    // MARK: - Connection

    private func handleConnect(address: String, uuid: String, result: @escaping FlutterResult) {
        guard let device = IOBluetoothDevice(addressString: address) else {
            result(FlutterError(code: "connectionFailed", message: "Invalid device address", details: ["address": address]))
            return
        }

        let sdpUUID = uuidFromString(uuid)
        let connId = nextConnectionId
        nextConnectionId += 1

        let wrapper = BluetoothConnectionWrapper(id: connId, device: device, messenger: messenger)
        connections[connId] = wrapper

        wrapper.open(uuid: sdpUUID) { success in
            if success {
                result(["id": connId, "address": address])
            } else {
                self.connections.removeValue(forKey: connId)
                result(FlutterError(code: "connectionFailed", message: "Failed to connect", details: ["address": address]))
            }
        }
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

    // MARK: - Server

    private func handleStartServer(uuid: String, serviceName: String, result: @escaping FlutterResult) {
        let serverId = nextServerId
        nextServerId += 1

        let server = BluetoothServerWrapper(id: serverId, uuid: uuid, serviceName: serviceName, messenger: messenger)
        let started = server.start { [weak self] connId, wrapper in
            self?.connections[connId] = wrapper
        }

        if started {
            servers[serverId] = server
            result(["id": serverId])
        } else {
            result(FlutterError(code: "connectionFailed", message: "Failed to start server", details: nil))
        }
    }

    private func handleStopServer(id: Int, result: @escaping FlutterResult) {
        if let server = servers.removeValue(forKey: id) {
            server.stop()
        }
        result(nil)
    }

    // MARK: - Capabilities

    private func handleGetPlatformCapabilities(result: @escaping FlutterResult) {
        result([
            "canEnableBluetooth": false,
            "canDisableBluetooth": false,
            // Discovery, bonding and server mode are not yet implemented on
            // macOS (IOBluetooth inquiry/pairing/channel-open notifications are
            // not wired up); report them honestly so apps don't call into
            // non-functional paths. Connect/read/write and paired-device
            // enumeration do work.
            "canDiscoverDevices": false,
            "canGetPairedDevices": true,
            "canBondDevices": false,
            "canUnbondDevices": false,
            "canCreateServer": false,
            "canSetDiscoverable": false,
            "supportsMultipleConnections": true,
            "supportsSecureConnection": true,
            "supportsInsecureConnection": false,
            "requiresMfiCertification": false,
            "platformNote": "macOS — Bluetooth Classic via IOBluetooth. Connect/read/write and paired-device listing are supported; discovery, bonding and server mode are not yet implemented."
        ])
    }

    // MARK: - Helpers

    private func deviceToMap(_ device: IOBluetoothDevice) -> [String: Any?] {
        let uuids = (device.services as? [IOBluetoothSDPServiceRecord])?.compactMap {
            $0.getServiceName()
        } ?? []
        let raw = device.rawRSSI()
        let rssi: Int? = raw != 127 ? Int(raw) : nil  // 127 == not available
        return [
            "address": device.addressString?.replacingOccurrences(of: "-", with: ":").uppercased(),
            "name": device.name,
            "alias": nil,
            "rssi": rssi,
            "type": "classic",
            "bondState": device.isPaired() ? "bonded" : "none",
            "uuids": uuids,
            "isConnected": device.isConnected()
        ]
    }

    private func uuidFromString(_ str: String) -> IOBluetoothSDPUUID {
        let cleaned = str.replacingOccurrences(of: "-", with: "")
        var bytes = [UInt8]()
        var index = cleaned.startIndex
        for _ in 0..<(cleaned.count / 2) {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            if let byte = UInt8(cleaned[index..<nextIndex], radix: 16) {
                bytes.append(byte)
            }
            index = nextIndex
        }
        return IOBluetoothSDPUUID(bytes: &bytes, length: UInt32(bytes.count))
    }
}

// MARK: - Device Inquiry Delegate

private class DeviceInquiryDelegate: NSObject, IOBluetoothDeviceInquiryDelegate {
    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        onComplete()
    }
}

// MARK: - Bluetooth Connection Wrapper

class BluetoothConnectionWrapper: NSObject, IOBluetoothRFCOMMChannelDelegate {
    let id: Int
    let device: IOBluetoothDevice
    private var channel: IOBluetoothRFCOMMChannel?
    private var messenger: FlutterBinaryMessenger
    private var dataEventSink: FlutterEventSink?
    private var stateEventSink: FlutterEventSink?
    private var dataStreamHandler: StreamHandler?
    private var stateStreamHandler: StreamHandler?
    private var completion: ((Bool) -> Void)?

    init(id: Int, device: IOBluetoothDevice, messenger: FlutterBinaryMessenger) {
        self.id = id
        self.device = device
        self.messenger = messenger
        super.init()
        setupEventChannels()
    }

    private func setupEventChannels() {
        let dataHandler = StreamHandler()
        dataStreamHandler = dataHandler
        let dataChannel = FlutterEventChannel(
            name: "flutter_classic_bluetooth/connection/\(id)",
            binaryMessenger: messenger
        )
        dataChannel.setStreamHandler(dataHandler)

        let stateHandler = StreamHandler()
        stateStreamHandler = stateHandler
        let stateChannel = FlutterEventChannel(
            name: "flutter_classic_bluetooth/connection_state/\(id)",
            binaryMessenger: messenger
        )
        stateChannel.setStreamHandler(stateHandler)
    }

    func open(uuid: IOBluetoothSDPUUID, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        // Find the matching service record
        guard let serviceRecord = device.getServiceRecord(for: uuid) else {
            // Try opening RFCOMM directly on channel 1
            var rfcommChannel: IOBluetoothRFCOMMChannel?
            let result = device.openRFCOMMChannelSync(&rfcommChannel, withChannelID: 1, delegate: self)
            if result == kIOReturnSuccess, let ch = rfcommChannel {
                self.channel = ch
                stateStreamHandler?.eventSink?("connected")
                completion(true)
            } else {
                completion(false)
            }
            return
        }

        var channelID: BluetoothRFCOMMChannelID = 0
        serviceRecord.getRFCOMMChannelID(&channelID)

        var rfcommChannel: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelSync(&rfcommChannel, withChannelID: channelID, delegate: self)
        if result == kIOReturnSuccess, let ch = rfcommChannel {
            self.channel = ch
            stateStreamHandler?.eventSink?("connected")
            completion(true)
        } else {
            completion(false)
        }
    }

    func write(data: Data) -> Bool {
        guard let channel = channel else { return false }
        var mutableData = [UInt8](data)
        let result = channel.writeSync(&mutableData, length: UInt16(mutableData.count))
        return result == kIOReturnSuccess
    }

    func close() {
        channel?.closeChannel()
        channel = nil
        stateStreamHandler?.eventSink?("disconnected")
    }

    // IOBluetoothRFCOMMChannelDelegate
    // These fire on IOBluetooth's run loop; Flutter event sinks must be invoked
    // on the main thread.
    public func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: dataLength)
        DispatchQueue.main.async { [weak self] in
            self?.dataStreamHandler?.eventSink?(FlutterStandardTypedData(bytes: data))
        }
    }

    public func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        channel = nil
        DispatchQueue.main.async { [weak self] in
            self?.stateStreamHandler?.eventSink?("disconnected")
        }
    }
}

// MARK: - Bluetooth Server Wrapper

class BluetoothServerWrapper: NSObject {
    let id: Int
    let uuid: String
    let serviceName: String
    private var messenger: FlutterBinaryMessenger
    private var sdpRecord: IOBluetoothSDPServiceRecord?

    init(id: Int, uuid: String, serviceName: String, messenger: FlutterBinaryMessenger) {
        self.id = id
        self.uuid = uuid
        self.serviceName = serviceName
        self.messenger = messenger
    }

    func start(onConnection: @escaping (Int, BluetoothConnectionWrapper) -> Void) -> Bool {
        let serviceDict: [String: Any] = [
            "0001 - ServiceClassIDList": [uuid],
            "0100 - ServiceName*": serviceName
        ]
        guard let record = IOBluetoothSDPServiceRecord.publishedServiceRecord(with: serviceDict) else {
            return false
        }
        sdpRecord = record
        return true
    }

    func stop() {
        sdpRecord?.removeServiceRecord()
        sdpRecord = nil
    }
}

// MARK: - Stream Handler

private class StreamHandler: NSObject, FlutterStreamHandler {
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
