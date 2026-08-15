package com.flutter_classic_bluetooth.flutter_classic_bluetooth

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.SparseArray
import java.util.concurrent.atomic.AtomicInteger
import com.flutter_classic_bluetooth.flutter_classic_bluetooth.receivers.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.lang.reflect.InvocationTargetException
import java.util.UUID

class FlutterClassicBluetoothPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var messenger: io.flutter.plugin.common.BinaryMessenger

    private var adapter: BluetoothAdapter? = null
    private val permissionManager = PermissionManager()
    private val activityResultManager = ActivityResultManager()

    private val connections = SparseArray<BluetoothConnectionWrapper>()
    private val servers = SparseArray<BluetoothServerSocketWrapper>()
    // Single source of truth for ids shared by client connects and server
    // accepts, so the two can never collide.
    private val nextConnectionId = AtomicInteger(1)
    private val nextServerId = AtomicInteger(1)

    // MethodChannel.Result and EventChannel registration must run on the main
    // (platform) thread; Bluetooth I/O runs on background threads.
    private val mainHandler = Handler(Looper.getMainLooper())

    // Detects when a remote Bluetooth device physically disconnects (e.g.
    // printer turned off) and emits "disconnected" on the matching connection's
    // state stream.
    private var aclDisconnectReceiver: AclDisconnectReceiver? = null

    // Event channels
    private lateinit var adapterStateChannel: EventChannel
    private lateinit var discoveryStateChannel: EventChannel
    private lateinit var discoveryResultsChannel: EventChannel
    private lateinit var bondStateChannel: EventChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        messenger = binding.binaryMessenger

        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        adapter = btManager?.adapter

        channel = MethodChannel(messenger, BluetoothHelper.METHOD_CHANNEL)
        channel.setMethodCallHandler(this)

        adapterStateChannel = EventChannel(messenger, BluetoothHelper.ADAPTER_STATE_CHANNEL)
        adapterStateChannel.setStreamHandler(AdapterStateReceiver(context))

        discoveryStateChannel = EventChannel(messenger, BluetoothHelper.DISCOVERY_STATE_CHANNEL)
        discoveryStateChannel.setStreamHandler(DiscoveryStateReceiver(context))

        discoveryResultsChannel = EventChannel(messenger, BluetoothHelper.DISCOVERY_RESULTS_CHANNEL)
        discoveryResultsChannel.setStreamHandler(ScanResultReceiver(context))

        bondStateChannel = EventChannel(messenger, BluetoothHelper.BOND_STATE_CHANNEL)
        bondStateChannel.setStreamHandler(BondStateReceiver(context))

        aclDisconnectReceiver = AclDisconnectReceiver(connections)
        BluetoothHelper.registerExportedReceiver(
            context, aclDisconnectReceiver!!, IntentFilter(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        aclDisconnectReceiver?.let { context.unregisterReceiver(it) }
        aclDisconnectReceiver = null
        closeAll()
    }

    // ── ActivityAware ──────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        permissionManager.setActivity(binding.activity)
        activityResultManager.activity = binding.activity
        binding.addRequestPermissionsResultListener(permissionManager)
        binding.addActivityResultListener(activityResultManager)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        permissionManager.setActivity(null)
        activityResultManager.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        permissionManager.setActivity(binding.activity)
        activityResultManager.activity = binding.activity
        binding.addRequestPermissionsResultListener(permissionManager)
        binding.addActivityResultListener(activityResultManager)
    }

    override fun onDetachedFromActivity() {
        permissionManager.setActivity(null)
        activityResultManager.activity = null
    }

    // ── Method Call Handler ────────────────────────────────────────────

    @Suppress("MissingPermission")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isSupported" -> result.success(
                context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)
            )
            "isEnabled" -> result.success(adapter?.isEnabled == true)

            "enableBluetooth" -> handleEnableBluetooth(result)
            "disableBluetooth" -> handleDisableBluetooth(result)

            "getAdapterName" -> permissionManager.ensurePermissions(context, result) {
                result.success(adapter?.name)
            }
            "getAdapterAddress" -> permissionManager.ensurePermissions(context, result) {
                result.success(adapter?.address)
            }

            "startDiscovery" -> handleStartDiscovery(result)
            "stopDiscovery" -> handleStopDiscovery(result)
            "isDiscovering" -> result.success(adapter?.isDiscovering == true)

            "getPairedDevices" -> handleGetPairedDevices(result)
            "bondDevice" -> handleBondDevice(call, result)
            "unbondDevice" -> handleUnbondDevice(call, result)

            "connect" -> handleConnect(call, result)
            "cancelConnect" -> handleCancelConnect(call, result)
            "disconnect" -> handleDisconnect(call, result)
            "write" -> handleWrite(call, result)

            "startServer" -> handleStartServer(call, result)
            "stopServer" -> handleStopServer(call, result)

            "setDiscoverable" -> handleSetDiscoverable(call, result)
            "getPlatformCapabilities" -> handleGetPlatformCapabilities(result)

            else -> result.notImplemented()
        }
    }

    // ── Adapter ────────────────────────────────────────────────────────

    private fun handleEnableBluetooth(result: Result) {
        if (adapter?.isEnabled == true) {
            result.success(true)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            activityResultManager.startActivityForResult(
                intent, ActivityResultManager.REQUEST_ENABLE_BT, result
            )
        }
    }

    @Suppress("MissingPermission")
    private fun handleDisableBluetooth(result: Result) {
        if (adapter == null) {
            result.error("bluetoothDisabled", "No Bluetooth adapter", null)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            @Suppress("DEPRECATION")
            val success = adapter!!.disable()
            result.success(success)
        }
    }

    // ── Discovery ──────────────────────────────────────────────────────

    @Suppress("MissingPermission")
    private fun handleStartDiscovery(result: Result) {
        val bt = adapter
        if (bt == null) {
            result.error("bluetoothDisabled", "No Bluetooth adapter", null)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            if (bt.isDiscovering) bt.cancelDiscovery()
            val started = bt.startDiscovery()
            if (started) result.success(null)
            else result.error("discoveryFailed", "Failed to start discovery", null)
        }
    }

    @Suppress("MissingPermission")
    private fun handleStopDiscovery(result: Result) {
        permissionManager.ensurePermissions(context, result) {
            adapter?.cancelDiscovery()
            result.success(null)
        }
    }

    // ── Pairing ────────────────────────────────────────────────────────

    @Suppress("MissingPermission")
    private fun handleGetPairedDevices(result: Result) {
        val bt = adapter
        if (bt == null) {
            result.error("bluetoothDisabled", "No Bluetooth adapter", null)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            val devices = bt.bondedDevices
                ?.filter { it.type != BluetoothDevice.DEVICE_TYPE_LE }
                ?.map { BluetoothHelper.deviceToMap(it) }
                ?: emptyList()
            result.success(devices)
        }
    }

    @Suppress("MissingPermission")
    private fun handleBondDevice(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")
        if (address == null) {
            result.error("invalidAddress", "Address is required", null)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            val device = adapter?.getRemoteDevice(address)
            if (device == null) {
                result.error("invalidAddress", "Device not found: $address", null)
                return@ensurePermissions
            }
            val success = device.createBond()
            result.success(success)
        }
    }

    @Suppress("MissingPermission")
    private fun handleUnbondDevice(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")
        if (address == null) {
            result.error("invalidAddress", "Address is required", null)
            return
        }
        permissionManager.ensurePermissions(context, result) {
            val device = adapter?.getRemoteDevice(address)
            if (device == null) {
                result.error("invalidAddress", "Device not found: $address", null)
                return@ensurePermissions
            }
            try {
                val method = device.javaClass.getMethod("removeBond")
                val success = method.invoke(device) as Boolean
                result.success(success)
            } catch (e: Exception) {
                result.error("unsupported", "Unbond not available: ${e.message}",
                    mapOf("feature" to "unbondDevice", "platform" to "Android"))
            }
        }
    }

    // ── Connection ─────────────────────────────────────────────────────

    @Suppress("MissingPermission")
    /**
     * Sockets currently blocked in `connect()`, by address.
     *
     * `BluetoothSocket.connect()` has no timeout and no interrupt. A Dart-side
     * `Future.timeout` stops the caller waiting but leaves the native call
     * blocked, holding the device against every later attempt until the app is
     * restarted. Closing the socket is the only thing that unblocks it, and
     * before this there was nothing to close it *with* — the socket did not
     * enter `connections` until after a successful connect.
     */
    private val inFlight = HashMap<String, BluetoothSocket>()

    /** Aborts an in-flight connect by closing the socket it is blocked on. */
    private fun handleCancelConnect(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")
        if (address == null) {
            result.error("invalidAddress", "Address is required", null)
            return
        }
        val socket = synchronized(inFlight) { inFlight.remove(address) }
        try { socket?.close() } catch (_: IOException) {}
        result.success(socket != null)
    }

    private fun handleConnect(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")
        val uuidStr = call.argument<String>("uuid") ?: BluetoothHelper.DEFAULT_UUID
        val secure = call.argument<Boolean>("secure") ?: true
        val channel = call.argument<Int>("channel")

        if (address == null) {
            result.error("invalidAddress", "Address is required", null)
            return
        }

        permissionManager.ensurePermissions(context, result) {
            Thread {
                try {
                    val device = adapter?.getRemoteDevice(address)
                    if (device == null) {
                        mainHandler.post {
                            result.error("connectionFailed", "Device not found: $address",
                                mapOf("address" to address))
                        }
                        return@Thread
                    }

                    // Cancel discovery to speed up connection
                    adapter?.cancelDiscovery()

                    // Held here so every exit that has not handed ownership
                    // to `connections` can close it. Both catch blocks used to
                    // report the failure and drop the socket on the floor:
                    // each failed attempt leaked a file descriptor and left
                    // Bluetooth stack state behind, and a caller walking a
                    // three-tier fallback leaked three.
                    var pending: BluetoothSocket? = null
                    try {
                    val socket = if (channel != null) {
                        openChannelSocket(device, channel, secure)
                    } else {
                        val uuid = UUID.fromString(uuidStr)
                        if (secure) {
                            device.createRfcommSocketToServiceRecord(uuid)
                        } else {
                            device.createInsecureRfcommSocketToServiceRecord(uuid)
                        }
                    }
                    pending = socket

                    synchronized(inFlight) { inFlight.put(address, socket) }
                    try {
                        socket.connect()
                    } finally {
                        synchronized(inFlight) { inFlight.remove(address) }
                    }

                    val connId = nextConnectionId.getAndIncrement()
                    val connection = BluetoothConnectionWrapper(
                        id = connId,
                        socket = socket,
                        address = address,
                    )

                    synchronized(connections) {
                        connections.put(connId, connection)
                    }
                    // Ownership transferred: `handleDisconnect` can reach it now.
                    pending = null

                    // Channel registration + result delivery must be on the main
                    // thread; do it before completing the Future so Dart can
                    // listen as soon as it has the id.
                    mainHandler.post {
                        EventChannel(messenger, BluetoothHelper.connectionChannel(connId))
                            .setStreamHandler(connection.dataStreamHandler)
                        EventChannel(messenger, BluetoothHelper.connectionStateChannel(connId))
                            .setStreamHandler(connection.stateStreamHandler)
                        result.success(mapOf("id" to connId, "address" to address))
                    }
                    } finally {
                        try { pending?.close() } catch (_: IOException) {}
                    }
                } catch (e: IOException) {
                    mainHandler.post {
                        result.error("connectionFailed", "Connection failed: ${e.message}",
                            mapOf("address" to address))
                    }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("connectionFailed", "Connection failed: ${e.message}",
                            mapOf("address" to address))
                    }
                }
            }.apply {
                isDaemon = true
                name = "bt-connect"
                start()
            }
        }
    }

    /**
     * Opens an RFCOMM socket on an explicit channel, bypassing SDP.
     *
     * Both public factory methods — `createRfcommSocketToServiceRecord` and its
     * insecure twin — perform a service-discovery lookup and fail when the
     * device does not publish a usable SPP record. A large family of cheap
     * serial adapters, ELM327 OBD-II clones in particular, simply listen on
     * channel 1 and advertise nothing: they pair normally and then cannot be
     * connected to at all.
     *
     * Android does expose `createRfcommSocket(int)` and
     * `createInsecureRfcommSocket(int)` on [BluetoothDevice], but they are
     * hidden from the SDK, so reflection is the only route. They have been
     * reachable this way for many releases and are what OBD-II apps on the
     * platform rely on. Should a future release restrict them, that is reported
     * plainly rather than degrading into a generic connection failure.
     */
    @Throws(IOException::class)
    private fun openChannelSocket(
        device: BluetoothDevice,
        channel: Int,
        secure: Boolean,
    ): BluetoothSocket {
        require(channel in 1..30) { "RFCOMM channel must be 1-30, got $channel" }
        val methodName =
            if (secure) "createRfcommSocket" else "createInsecureRfcommSocket"
        try {
            val method =
                device.javaClass.getMethod(methodName, Int::class.javaPrimitiveType)
            return method.invoke(device, channel) as BluetoothSocket
        } catch (e: InvocationTargetException) {
            // Unwrap, so the caller sees the IOException the socket layer threw
            // rather than a reflection wrapper around it.
            val cause = e.cause
            if (cause is IOException) throw cause
            throw IOException(
                "Failed to open RFCOMM channel $channel: ${cause?.message ?: e.message}",
                e,
            )
        } catch (e: Exception) {
            throw IOException(
                "This Android build does not expose $methodName(int); " +
                    "explicit-channel connections are unavailable here",
                e,
            )
        }
    }

    private fun handleDisconnect(call: MethodCall, result: Result) {
        val id = call.argument<Int>("id")
        if (id == null) {
            result.error("connectionFailed", "Connection ID is required", null)
            return
        }
        val connection = synchronized(connections) { connections.get(id) }
        if (connection == null) {
            result.error("connectionFailed", "Connection not found: $id", null)
            return
        }
        connection.close()
        synchronized(connections) { connections.remove(id) }
        result.success(null)
    }

    private fun handleWrite(call: MethodCall, result: Result) {
        val id = call.argument<Int>("id")
        val data = call.argument<ByteArray>("data")
        if (id == null || data == null) {
            result.error("writeFailed", "Connection ID and data are required", null)
            return
        }
        val connection = synchronized(connections) { connections.get(id) }
        if (connection == null) {
            result.error("connectionFailed", "Connection not found: $id", null)
            return
        }
        connection.writeAsync(data) { error ->
            mainHandler.post {
                if (error == null) {
                    result.success(null)
                } else {
                    result.error("writeFailed", "Write failed: ${error.message}", null)
                }
            }
        }
    }

    // ── Server ─────────────────────────────────────────────────────────

    @Suppress("MissingPermission")
    private fun handleStartServer(call: MethodCall, result: Result) {
        val uuidStr = call.argument<String>("uuid") ?: BluetoothHelper.DEFAULT_UUID
        val serviceName = call.argument<String>("serviceName") ?: "FlutterBluetooth"
        val secure = call.argument<Boolean>("secure") ?: true
        val channel = call.argument<Int>("channel")

        val bt = adapter
        if (bt == null) {
            result.error("bluetoothDisabled", "No Bluetooth adapter", null)
            return
        }

        permissionManager.ensurePermissions(context, result) {
            try {
                val serverId = nextServerId.getAndIncrement()
                val server = BluetoothServerSocketWrapper(
                    id = serverId,
                    adapter = bt,
                    uuid = uuidStr,
                    serviceName = serviceName,
                    secure = secure,
                    connectionIdSource = nextConnectionId,
                    // Invoked on the main thread by the wrapper.
                    onConnectionAccepted = { connection ->
                        synchronized(connections) {
                            connections.put(connection.id, connection)
                        }
                        EventChannel(messenger, BluetoothHelper.connectionChannel(connection.id))
                            .setStreamHandler(connection.dataStreamHandler)
                        EventChannel(messenger, BluetoothHelper.connectionStateChannel(connection.id))
                            .setStreamHandler(connection.stateStreamHandler)
                    }
                )

                val serverChannel = EventChannel(messenger, BluetoothHelper.serverChannel(serverId))
                serverChannel.setStreamHandler(server.streamHandler)

                synchronized(servers) {
                    servers.put(serverId, server)
                }

                server.start()
                result.success(mapOf("id" to serverId))
            } catch (e: IOException) {
                result.error("connectionFailed", "Failed to start server: ${e.message}", null)
            }
        }
    }

    private fun handleStopServer(call: MethodCall, result: Result) {
        val id = call.argument<Int>("id")
        if (id == null) {
            result.error("connectionFailed", "Server ID is required", null)
            return
        }
        val server = synchronized(servers) { servers.get(id) }
        if (server == null) {
            result.error("connectionFailed", "Server not found: $id", null)
            return
        }
        server.close()
        synchronized(servers) { servers.remove(id) }
        result.success(null)
    }

    // ── Discoverability ────────────────────────────────────────────────

    private fun handleSetDiscoverable(call: MethodCall, result: Result) {
        val duration = call.argument<Int>("duration") ?: 120
        permissionManager.ensurePermissions(context, result) {
            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
                putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration)
            }
            activityResultManager.startActivityForResult(
                intent, ActivityResultManager.REQUEST_DISCOVERABLE, result
            )
        }
    }

    // ── Capabilities ───────────────────────────────────────────────────

    private fun handleGetPlatformCapabilities(result: Result) {
        result.success(
            mapOf(
                "canEnableBluetooth" to true,
                "canDisableBluetooth" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU),
                "canDiscoverDevices" to true,
                "canGetPairedDevices" to true,
                "canBondDevices" to true,
                "canUnbondDevices" to true,
                "canCreateServer" to true,
                "canSetDiscoverable" to true,
                "supportsMultipleConnections" to true,
                "supportsSecureConnection" to true,
                "supportsInsecureConnection" to true,
                "requiresMfiCertification" to false,
                "platformNote" to "Android: full Bluetooth Classic support. unbondDevice uses reflection (hidden API)."
            )
        )
    }

    // ── Cleanup ────────────────────────────────────────────────────────

    private fun closeAll() {
        synchronized(connections) {
            for (i in 0 until connections.size()) {
                connections.valueAt(i).close()
            }
            connections.clear()
        }
        synchronized(servers) {
            for (i in 0 until servers.size()) {
                servers.valueAt(i).close()
            }
            servers.clear()
        }
    }
}
