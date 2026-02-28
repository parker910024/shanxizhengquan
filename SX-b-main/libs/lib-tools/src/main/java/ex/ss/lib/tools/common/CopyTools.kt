package ex.ss.lib.tools.common

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context

object CopyTools {

    fun copy(context: Context, text: String, label: String = "copy"): Boolean {
        return runCatching {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip: ClipData = ClipData.newPlainText(label, text)
            clipboard.setPrimaryClip(clip)
            true
        }.getOrElse { false }
    }
}