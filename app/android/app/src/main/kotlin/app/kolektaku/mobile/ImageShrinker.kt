package app.kolektaku.mobile

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import java.io.ByteArrayOutputStream

object ImageShrinker {
    const val MAX_WIDTH = 640
    const val JPEG_QUALITY = 85

    fun sampleSize(width: Int, maxWidth: Int): Int {
        var size = 1
        while (width / (size * 2) >= maxWidth) {
            size *= 2
        }
        return size
    }

    fun targetHeight(width: Int, height: Int, maxWidth: Int): Int {
        if (width <= maxWidth) return height
        return (height.toLong() * maxWidth / width).toInt().coerceAtLeast(1)
    }

    fun shrink(resolver: ContentResolver, uri: Uri): ByteArray? {
        return try {
            decodeAndCompress(resolver, uri)
        } catch (error: Exception) {
            null
        } catch (error: OutOfMemoryError) {
            null
        }
    }

    private fun decodeAndCompress(resolver: ContentResolver, uri: Uri): ByteArray? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, MAX_WIDTH)
        }
        val decoded = resolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, options)
        } ?: return null
        val height = targetHeight(decoded.width, decoded.height, MAX_WIDTH)
        val scaled = if (decoded.width > MAX_WIDTH) {
            Bitmap.createScaledBitmap(decoded, MAX_WIDTH, height, true)
        } else {
            decoded
        }
        return ByteArrayOutputStream().use { output ->
            scaled.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, output)
            output.toByteArray()
        }
    }
}
