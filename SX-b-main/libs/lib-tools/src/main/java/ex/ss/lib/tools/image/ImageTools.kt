package ex.ss.lib.tools.image

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import ex.ss.lib.tools.extension.ifNullOrEmpty
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.Closeable
import java.io.File
import java.io.FileInputStream

object ImageTools {

    suspend fun saveBitmap2Gallery(context: Context, bitmap: Bitmap): Pair<Boolean, Uri?> {
        val file = bitmapToFile(context, bitmap)
        return saveFile2Gallery(context, file.absolutePath).let {
            if (!it.first) {
                val result = bitmap.saveToAlbum(context, "${System.currentTimeMillis()}.jpg")
                (result != null) to result
            } else it
        }
    }

    suspend fun bitmapToFile(context: Context, bitmap: Bitmap): File = withContext(Dispatchers.IO) {
        val fileDir = context.getExternalFilesDir(Environment.DIRECTORY_DCIM)
        val file = File(fileDir, "${System.currentTimeMillis()}.png")
        file.outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 0, it)
            it.flush()
        }
        return@withContext file
    }

    suspend fun saveFile2Gallery(context: Context, filePath: String): Pair<Boolean, Uri?> {
        return withContext(Dispatchers.IO) {
            saveImageToAlbum(context, filePath)
        }
    }

    private fun getFileName(url: String?): String? {
        var fileName: String? = null
        if (url != null && url.contains("/")) {
            val data = url.split("/").toTypedArray()
            fileName = data[data.size - 1]
        }
        return fileName
    }

    private fun getUriForFile(context: Context, file: File): Uri {
        return if (Build.VERSION.SDK_INT >= 24) {
            getUriForFile24(context, file)
        } else {
            Uri.fromFile(file)
        }
    }

    private fun getUriForFile24(context: Context, file: File): Uri {
        val authority = context.packageName + ".fileprovider"
        return FileProvider.getUriForFile(context, authority, file)
    }

    private fun close(vararg closeables: Closeable?) {
        for (closeable in closeables) {
            if (closeable == null) continue
            try {
                closeable.close()
            } catch (ignore: Throwable) {
            }
        }
    }

    private fun saveImageToAlbum(context: Context, filePath: String): Pair<Boolean, Uri?> {
        val name = getFileName(filePath)
        val values = ContentValues()
        val ext = File(filePath).extension.ifNullOrEmpty { "png" }
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, name)
        values.put(MediaStore.MediaColumns.MIME_TYPE, "image/$ext")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DCIM)
        } else {
            values.put(
                MediaStore.MediaColumns.DATA,
                "${Environment.getExternalStorageDirectory().path}/${Environment.DIRECTORY_DCIM}/$name"
            )
        }
        val uri =
            context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return false to getUriForFile(context, File(filePath))
        val outputStream =
            kotlin.runCatching { context.contentResolver.openOutputStream(uri) }.getOrNull()
                ?: return false to getUriForFile(context, File(filePath))
        val resultCopy = kotlin.runCatching {
            val bis = BufferedInputStream(FileInputStream(filePath))
            val bos = BufferedOutputStream(outputStream)
            val buffer = ByteArray(1024)
            var bytes = bis.read(buffer)
            while (bytes >= 0) {
                bos.write(buffer, 0, bytes)
                bos.flush()
                bytes = bis.read(buffer)
            }
            close(bos, bis)
            true
        }.getOrDefault(false)

        return resultCopy to if (resultCopy) uri else getUriForFile(context, File(filePath))
    }
}