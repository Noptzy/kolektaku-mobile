package app.kolektaku.mobile

import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PipController(
    private val activity: Activity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    private var armed = false
    private var playing = false
    private var aspect = Rational(16, 9)
    private var receiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }
        when (call.method) {
            "arm" -> arm(call, result)
            "update" -> update(call, result)
            "disarm" -> disarm(result)
            "enterNow" -> result.success(activity.enterPictureInPictureMode(params()))
            else -> result.notImplemented()
        }
    }

    private fun arm(call: MethodCall, result: MethodChannel.Result) {
        val width = call.argument<Int>("width") ?: 16
        val height = call.argument<Int>("height") ?: 9
        aspect = Rational(width.coerceAtLeast(1), height.coerceAtLeast(1))
        playing = call.argument<Boolean>("playing") ?: false
        armed = true
        apply()
        result.success(true)
    }

    private fun update(call: MethodCall, result: MethodChannel.Result) {
        playing = call.argument<Boolean>("playing") ?: playing
        apply()
        result.success(true)
    }

    private fun disarm(result: MethodChannel.Result) {
        armed = false
        apply()
        result.success(true)
    }

    private fun apply() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.setPictureInPictureParams(params())
        }
    }

    private fun params(): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(aspect)
            .setActions(listOf(toggleAction()))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(armed)
        }
        return builder.build()
    }

    private fun toggleAction(): RemoteAction {
        val icon = if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val title = if (playing) "Jeda" else "Putar"
        val intent = Intent(ACTION_TOGGLE).setPackage(activity.packageName)
        val pending = PendingIntent.getBroadcast(
            activity,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return RemoteAction(Icon.createWithResource(activity, icon), title, title, pending)
    }

    fun onUserLeaveHint() {
        val needsManualEntry = Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        if (armed && needsManualEntry && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.enterPictureInPictureMode(params())
        }
    }

    fun onModeChanged(inPip: Boolean) {
        if (inPip) listen() else stopListening()
        channel.invokeMethod("modeChanged", inPip)
    }

    private fun listen() {
        stopListening()
        val toggle = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                channel.invokeMethod("action", "toggle")
            }
        }
        ContextCompat.registerReceiver(
            activity,
            toggle,
            IntentFilter(ACTION_TOGGLE),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        receiver = toggle
    }

    private fun stopListening() {
        receiver?.let { activity.unregisterReceiver(it) }
        receiver = null
    }

    fun release() {
        stopListening()
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val CHANNEL_NAME = "app.kolektaku.mobile/pip"
        const val ACTION_TOGGLE = "app.kolektaku.mobile.PIP_TOGGLE"
    }
}
