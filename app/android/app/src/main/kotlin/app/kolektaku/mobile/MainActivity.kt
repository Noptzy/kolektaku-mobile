package app.kolektaku.mobile

import android.content.Intent
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pip: PipController? = null
    private var share: ShareReceiverPlugin? = null
    private var awake: ScreenAwakePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(ApkInstallerPlugin())
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        pip = PipController(this, MethodChannel(messenger, PipController.CHANNEL_NAME))
        awake = ScreenAwakePlugin(
            this,
            MethodChannel(messenger, ScreenAwakePlugin.CHANNEL_NAME),
        )
        DownloadPlugin(this, MethodChannel(messenger, DownloadPlugin.CHANNEL_NAME))
        share = ShareReceiverPlugin(
            this,
            MethodChannel(messenger, ShareReceiverPlugin.CHANNEL_NAME),
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        share?.onNewIntent(intent)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        pip?.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pip?.onModeChanged(isInPictureInPictureMode)
    }

    override fun onDestroy() {
        pip?.release()
        awake?.release()
        super.onDestroy()
    }
}
