package com.flutter_classic_bluetooth.flutter_classic_bluetooth

import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean

class BluetoothConnectionWrapper(
    val id: Int,
    private val socket: BluetoothSocket,
    val address: String,
) {
    private var readThread: Thread? = null
    private var dataEventSink: EventChannel.EventSink? = null
    private var stateEventSink: EventChannel.EventSink? = null

    // EventSink calls must happen on the main (platform) thread.
    private val mainHandler = Handler(Looper.getMainLooper())
    private val disconnectedEmitted = AtomicBoolean(false)

    @Volatile
    private var requestedClosing = false

    val isConnected: Boolean get() = socket.isConnected && !requestedClosing

    val inputStream: InputStream get() = socket.inputStream
    val outputStream: OutputStream get() = socket.outputStream

    val dataStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            dataEventSink = events
            startReading()
        }
        override fun onCancel(arguments: Any?) {
            dataEventSink = null
        }
    }

    val stateStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            stateEventSink = events
            // Report what is actually true, not what was true when the
            // connection was made. Re-listening after the link had dropped
            // replayed "connected" and told the app a dead socket was live.
            events.success(
                if (disconnectedEmitted.get() || !isConnected) "disconnected" else "connected"
            )
        }
        override fun onCancel(arguments: Any?) {
            stateEventSink = null
        }
    }

    /** Serialises writes off the platform thread, in submission order. */
    private val writer = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "bt-write-$id").apply { isDaemon = true }
    }

    private fun startReading() {
        // A second `onListen` — a Dart-side re-subscribe — used to start
        // another reader on the same InputStream. Two threads reading one
        // stream split the bytes between them arbitrarily, which for a
        // half-duplex protocol produces frames that parse and mean something
        // else entirely. One reader per connection, for its lifetime.
        if (readThread != null) return

        readThread = Thread {
            val buffer = ByteArray(1024)
            val input = try { inputStream } catch (_: IOException) { return@Thread }

            while (!requestedClosing) {
                try {
                    val bytesRead = input.read(buffer)
                    if (bytesRead == -1) break
                    val data = buffer.copyOf(bytesRead)
                    mainHandler.post { dataEventSink?.success(data) }
                } catch (_: IOException) {
                    break
                }
            }

            if (!requestedClosing) emitDisconnected()
        }.apply {
            isDaemon = true
            name = "bt-read-$id"
            start()
        }
    }

    /** Emits the terminal "disconnected" state exactly once, on the main thread. */
    private fun emitDisconnected() {
        if (!disconnectedEmitted.compareAndSet(false, true)) return
        mainHandler.post {
            stateEventSink?.success("disconnected")
            dataEventSink?.endOfStream()
        }
    }

    /**
     * Writes [data] on this connection's writer thread.
     *
     * [onComplete] receives null on success, or the failure. It runs on the
     * writer thread, so callers that need the platform thread must post.
     *
     * This used to write synchronously on whatever thread called it — which,
     * for a Flutter method-channel handler, is the platform main thread. A
     * wedged adapter with RFCOMM credit-based flow control exhausted blocks
     * `OutputStream.write` indefinitely, and the host app ANRs. Ordering is
     * preserved by the single-threaded executor, which a half-duplex ELM327
     * command chain depends on.
     */
    fun writeAsync(data: ByteArray, onComplete: (IOException?) -> Unit) {
        try {
            writer.execute {
                try {
                    outputStream.write(data)
                    outputStream.flush()
                    onComplete(null)
                } catch (e: IOException) {
                    onComplete(IOException("Failed to write to connection $id: ${e.message}"))
                }
            }
        } catch (_: RejectedExecutionException) {
            onComplete(IOException("Connection $id is closed"))
        }
    }

    fun close() {
        requestedClosing = true
        emitDisconnected()
        // Shut the writer down before closing the socket so a queued write
        // cannot fire against a closed stream.
        writer.shutdownNow()
        try { socket.close() } catch (_: IOException) {}
        readThread?.interrupt()
        readThread = null
    }
}
