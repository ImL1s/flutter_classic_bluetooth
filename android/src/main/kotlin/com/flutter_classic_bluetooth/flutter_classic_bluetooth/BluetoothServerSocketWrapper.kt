package com.flutter_classic_bluetooth.flutter_classic_bluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket as AndroidServerSocket
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.util.UUID

class BluetoothServerSocketWrapper(
    val id: Int,
    private val adapter: BluetoothAdapter,
    private val uuid: String,
    private val serviceName: String,
    private val secure: Boolean,
    private val onConnectionAccepted: (BluetoothConnectionWrapper) -> Unit,
) {
    private var serverSocket: AndroidServerSocket? = null
    private var acceptThread: Thread? = null
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var running = false
    private var nextConnectionId = 0

    val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            eventSink = events
        }
        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    @Suppress("MissingPermission")
    fun start(startConnectionId: Int) {
        nextConnectionId = startConnectionId
        val parsedUuid = UUID.fromString(uuid)

        serverSocket = if (secure) {
            adapter.listenUsingRfcommWithServiceRecord(serviceName, parsedUuid)
        } else {
            adapter.listenUsingInsecureRfcommWithServiceRecord(serviceName, parsedUuid)
        }

        running = true
        acceptThread = Thread {
            while (running) {
                try {
                    val socket = serverSocket?.accept() ?: break
                    val connId = nextConnectionId++
                    val connection = BluetoothConnectionWrapper(
                        id = connId,
                        socket = socket,
                        address = socket.remoteDevice.address,
                    )
                    onConnectionAccepted(connection)
                    eventSink?.success(
                        mapOf(
                            "id" to connId,
                            "address" to socket.remoteDevice.address,
                        )
                    )
                } catch (_: IOException) {
                    break
                }
            }
        }.apply {
            isDaemon = true
            name = "bt-server-$id"
            start()
        }
    }

    fun close() {
        running = false
        try { serverSocket?.close() } catch (_: IOException) {}
        serverSocket = null
        acceptThread?.interrupt()
        acceptThread = null
        eventSink = null
    }
}
