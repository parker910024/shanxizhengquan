package com.yanshu.app.util

import android.content.Intent
import android.net.Uri
import androidx.fragment.app.FragmentActivity
import kotlin.getOrElse
import kotlin.runCatching

object BrowserUtils {

    fun openBrowser(activity: FragmentActivity, link: String) = runCatching {
        val intent = Intent()
        intent.action = Intent.ACTION_VIEW
        intent.data = Uri.parse(link)
        activity.startActivity(intent)
        true
    }.getOrElse { false }
}