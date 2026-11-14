package app.kolektaku.mobile

import android.app.Activity
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ScreenAwakePlugin(
    private val activity: Activity,
    channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "keepOn" -> {
                apply(call.arguments == true)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    fun release() {
        apply(false)
    }

    private fun apply(on: Boolean) {
        activity.runOnUiThread {
            val window = activity.window
            if (on) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    companion object {
        const val CHANNEL_NAME = "app.kolektaku.mobile/awake"
    }
}
