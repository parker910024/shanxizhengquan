package ex.ss.lib.tools.common

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri

object BrowserTools {

    fun openBrowser(context: Context, link: String) = runCatching {
        val intent = Intent()
        intent.action = Intent.ACTION_VIEW
        intent.data = Uri.parse(link)
        if (context !is Activity) {
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
        true
    }.getOrElse { false }

}