package app.kolektaku.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

class DownloadService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Mengunduh"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
        val progress = intent?.getIntExtra(EXTRA_PROGRESS, -1) ?: -1
        val notification = build(this, title, text, progress)
        running = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    companion object {
        const val CHANNEL_ID = "kolektaku_downloads"
        const val NOTIFICATION_ID = 4107
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_PROGRESS = "progress"

        @Volatile
        var running = false

        fun update(context: Context, title: String, text: String, progress: Int) {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, build(context, title, text, progress))
        }

        private fun build(
            context: Context,
            title: String,
            text: String,
            progress: Int,
        ): Notification {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Unduhan",
                    NotificationManager.IMPORTANCE_LOW,
                )
                manager.createNotificationChannel(channel)
            }
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            return builder
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setProgress(100, progress.coerceIn(0, 100), progress < 0)
                .build()
        }
    }
}
