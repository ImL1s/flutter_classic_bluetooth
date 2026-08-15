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

    /**
     * Completion callbacks for writes that have been accepted but not yet run.
     *
     * `shutdownNow()` discards queued tasks, and a discarded task never invokes
     * its callback — so the Dart future for that write never completed. The
     * app's command chain is serial: one unfinished write parks every later
     * command behind it, and a fault-code scan sits on its spinner for good.
     * Closing has to answer every write it accepted.
     */
    private val pendingWrites = mutableListOf<PendingWrite>()

    /** A write's completion, answerable exactly once. */
    private class PendingWrite(private val onComplete: (IOException?) -> Unit) {
        private val done = AtomicBoolean(false)
        fun complete(error: IOException?): Boolean {
            if (!done.compareAndSet(false, true)) return false
            onComplete(error)
            return true
        }
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
        // Answered exactly once, by whichever of the writer thread or
        // `close()` reaches it first.
        val entry = PendingWrite(onComplete)
        synchronized(pendingWrites) { pendingWrites.add(entry) }

        fun finish(error: IOException?) {
            synchronized(pendingWrites) { pendingWrites.remove(entry) }
            entry.complete(error)
        }

        try {
            writer.execute {
                try {
                    outputStream.write(data)
                    outputStream.flush()
                    finish(null)
                } catch (e: IOException) {
                    finish(IOException("Failed to write to connection $id: ${e.message}"))
                }
            }
        } catch (_: RejectedExecutionException) {
            finish(IOException("Connection $id is closed"))
        }
    }

    fun close() {
        requestedClosing = true
        emitDisconnected()
        // Shut the writer down before closing the socket so a queued write
        // cannot fire against a closed stream — then answer every write that
        // was accepted and will now never run, because a caller waiting on one
        // of those waits forever.
        writer.shutdownNow()
        val orphaned = synchronized(pendingWrites) {
            val copy = pendingWrites.toList()
            pendingWrites.clear()
            copy
        }
        for (entry in orphaned) {
            entry.complete(IOException("Connection $id closed before the write ran"))
        }
        try { socket.close() } catch (_: IOException) {}
        readThread?.interrupt()
        readThread = null
    }
}
