package app.kolektaku.mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.IntentCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ShareReceiverPlugin(
    private val activity: Activity,
    channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    private var pending: ByteArray? = null

    init {
        channel.setMethodCallHandler(this)
        capture(activity.intent)
    }

    fun onNewIntent(intent: Intent) {
        capture(intent)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeSharedImage" -> {
                result.success(pending)
                pending = null
            }

            else -> result.notImplemented()
        }
    }

    private fun capture(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("image/") != true) return
        val uri = IntentCompat.getParcelableExtra(intent, Intent.EXTRA_STREAM, Uri::class.java)
            ?: return
        pending = ImageShrinker.shrink(activity.contentResolver, uri)
    }

    companion object {
        const val CHANNEL_NAME = "app.kolektaku.mobile/share"
    }
}
