package com.flutter_classic_bluetooth.flutter_classic_bluetooth

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class PermissionManager : PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val REQUEST_CODE = 29571
    }

    private var pendingResult: MethodChannel.Result? = null

    /** The action the outstanding request was made for. */
    private var pendingAction: Action? = null
    private var activity: Activity? = null

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    /**
     * What the caller is about to do.
     *
     * One permission set covered everything, which made supported adapters
     * unconnectable. Talking to a device the user has already paired is not
     * discovery: on Android 12+ it needs `BLUETOOTH_CONNECT` and not
     * `BLUETOOTH_SCAN`, and below that it needs no runtime permission at all —
     * `BLUETOOTH` and `BLUETOOTH_ADMIN` are install-time. Requiring fine
     * location before listing bonded devices asked for the user's whereabouts
     * to reach an adapter in their own car.
     *
     * `BLUETOOTH_ADVERTISE` was in the request set too, and a client never
     * needs it.
     */
    enum class Action { connect, discover, advertise }

    /** The permissions [action] actually requires on this Android version. */
    fun requiredPermissions(action: Action): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            when (action) {
                Action.connect -> arrayOf(Manifest.permission.BLUETOOTH_CONNECT)
                Action.discover -> arrayOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                )
                // Only a device making *itself* findable needs this, which is
                // the server side. A client was being asked for it too.
                Action.advertise -> arrayOf(
                    Manifest.permission.BLUETOOTH_ADVERTISE,
                    Manifest.permission.BLUETOOTH_CONNECT,
                )
            }
        } else {
            when (action) {
                // Install-time permissions cover these entirely.
                Action.connect, Action.advertise -> emptyArray()
                // Only discovery is gated behind location before Android 12.
                Action.discover -> arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
            }
        }

    fun hasPermissions(context: Context, action: Action = Action.discover): Boolean =
        requiredPermissions(action).all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }

    fun requestPermissions(result: MethodChannel.Result, action: Action = Action.discover) {
        val act = activity
        if (act == null) {
            result.error("permissionDenied", "No activity available to request permissions", null)
            return
        }

        if (hasPermissions(act, action)) {
            result.success(true)
            return
        }

        // Only one OS permission dialog can be outstanding; reject re-entrant
        // requests instead of overwriting (and orphaning) the previous result.
        if (pendingResult != null) {
            result.error("pendingOperation",
                "A permission request is already in progress", null)
            return
        }
        pendingResult = result
        // Kept beside the result, because the callback has to re-check the
        // action that was *requested*. It defaulted to `discover`, so a
        // connect-scoped request — which correctly asks for CONNECT alone —
        // was validated against discovery's CONNECT+SCAN set and reported
        // denied after the user had granted exactly what was asked for. The
        // retry then succeeds, which makes it look like a glitch rather than a
        // contract error.
        pendingAction = action

        ActivityCompat.requestPermissions(act, requiredPermissions(action), REQUEST_CODE)
    }

    fun ensurePermissions(
        context: Context,
        result: MethodChannel.Result,
        required: Action = Action.discover,
        action: () -> Unit,
    ) {
        if (hasPermissions(context, required)) {
            action()
        } else {
            requestPermissions(object : MethodChannel.Result {
                override fun success(r: Any?) {
                    if (r == true) action()
                    else result.error("permissionDenied", "Bluetooth permissions denied", null)
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    result.error(code, msg, details)
                }
                override fun notImplemented() {
                    result.notImplemented()
                }
            }, required)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        // Re-check the permissions the *request* required rather than every
        // grant returned; denying an optional permission must not fail an
        // otherwise-granted call. The action comes from the request, not from
        // the default — checking `discover`'s set after a `connect` request was
        // asking whether a permission nobody requested had been granted.
        val act = activity
        val action = pendingAction ?: Action.discover
        val granted = act != null && hasPermissions(act, action)
        pendingResult?.success(granted)
        pendingResult = null
        pendingAction = null
        return true
    }
}
