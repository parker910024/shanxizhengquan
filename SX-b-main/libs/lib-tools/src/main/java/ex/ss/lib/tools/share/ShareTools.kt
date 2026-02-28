package ex.ss.lib.tools.share

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

object ShareTools {

    fun shareFile(context: Context, file: File, title: String = "Share") {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        Intent(Intent.ACTION_SEND).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_STREAM, uri)
            type = context.contentResolver.getType(uri)
            context.startActivity(Intent.createChooser(this, title))
        }
    }

}