package com.flutter_classic_bluetooth.flutter_classic_bluetooth.receivers

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.SparseArray
import com.flutter_classic_bluetooth.flutter_classic_bluetooth.BluetoothConnectionWrapper

// Listens for system ACL disconnection events so we can immediately close the
// matching connection when a remote device goes away (e.g. printer turned off
// or moves out of range). The wrapper's close() emits "disconnected" on its
// state stream, so Dart is notified without extra plumbing here.
class AclDisconnectReceiver(
    private val connections: SparseArray<BluetoothConnectionWrapper>
) : BroadcastReceiver() {

    @Suppress("MissingPermission")
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != BluetoothDevice.ACTION_ACL_DISCONNECTED) return

        val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        } ?: return

        val address = device.address
        synchronized(connections) {
            for (i in 0 until connections.size()) {
                val conn = connections.valueAt(i)
                if (conn.address == address) {
                    conn.close()
                    connections.removeAt(i)
                    break
                }
            }
        }
    }
}
