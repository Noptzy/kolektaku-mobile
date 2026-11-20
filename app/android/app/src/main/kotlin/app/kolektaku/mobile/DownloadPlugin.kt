package app.kolektaku.mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DownloadPlugin(
    private val activity: Activity,
    channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "keepAlive" -> {
                keepAlive(call)
                result.success(null)
            }
            "publish" -> inBackground(result) {
                MediaExport.publish(activity, call.argument<String>("path") ?: "")
            }
            "delete" -> inBackground(result) {
                MediaExport.delete(activity, call.argument<String>("target") ?: "")
            }
            "open" -> result.success(
                open(call.argument<String>("target") ?: "", call.argument<String>("name") ?: ""),
            )
            else -> result.notImplemented()
        }
    }

    private fun inBackground(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            val answer = runCatching(work).getOrNull()
            main.post { result.success(answer) }
        }.start()
    }

    private fun keepAlive(call: MethodCall) {
        val intent = Intent(activity, DownloadService::class.java)
        if (call.argument<Boolean>("active") != true) {
            activity.stopService(intent)
            return
        }
        val title = call.argument<String>("title") ?: ""
        val text = call.argument<String>("text") ?: ""
        val progress = call.argument<Int>("progress") ?: -1
        if (DownloadService.running) {
            runCatching { DownloadService.update(activity, title, text, progress) }
            return
        }
        intent.putExtra(DownloadService.EXTRA_TITLE, title)
        intent.putExtra(DownloadService.EXTRA_TEXT, text)
        intent.putExtra(DownloadService.EXTRA_PROGRESS, progress)
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                activity.startForegroundService(intent)
            } else {
                activity.startService(intent)
            }
        }
    }

    private fun open(target: String, name: String): Boolean {
        if (!target.startsWith("content://")) return false
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(target), MediaExport.mimeOf(name))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return runCatching {
            activity.startActivity(Intent.createChooser(view, "Buka dengan"))
            true
        }.getOrDefault(false)
    }

    companion object {
        const val CHANNEL_NAME = "app.kolektaku.mobile/downloads"
    }
}
