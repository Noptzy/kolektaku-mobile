package app.kolektaku.mobile

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

object MediaExport {
    private const val FOLDER = "Kolektaku"

    fun mimeOf(name: String): String = when {
        name.endsWith(".mkv", ignoreCase = true) -> "video/x-matroska"
        else -> "video/mp4"
    }

    fun publish(context: Context, path: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val source = File(path)
        if (!source.isFile) return null
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, source.name)
            put(MediaStore.Video.Media.MIME_TYPE, mimeOf(source.name))
            put(
                MediaStore.Video.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_MOVIES}/$FOLDER",
            )
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val target = resolver.insert(collection, values) ?: return null
        return try {
            resolver.openOutputStream(target)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output, 1 shl 16) }
            } ?: throw IllegalStateException("no output")
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(target, values, null, null)
            source.delete()
            target.toString()
        } catch (error: Exception) {
            resolver.delete(target, null, null)
            null
        }
    }

    fun delete(context: Context, target: String): Boolean {
        return if (target.startsWith("content://")) {
            context.contentResolver.delete(Uri.parse(target), null, null) > 0
        } else {
            File(target).delete()
        }
    }
}
