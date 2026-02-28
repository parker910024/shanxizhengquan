package ex.ss.lib.tools.common

import android.content.Context
import android.os.Build
import android.provider.Settings

object DevicesTools {

    fun androidId(context: Context): String {
        return getAndroidId(context).let {
            if (it.isEmpty() || it.all { item -> item == '0' }) getCustomDeviceId() else it
        }
    }

    private fun getAndroidId(context: Context): String {
        return runCatching {
            Settings.System.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )
        }.getOrElse { "" }
    }

    private fun getCustomDeviceId(): String {
        return with(StringBuilder()) {
            append(runCatching { Build.BOARD }.getOrElse { "" })
            append(runCatching { Build.BRAND }.getOrElse { "" })
            append(runCatching { Build.DEVICE }.getOrElse { "" })
            append(runCatching { Build.HARDWARE }.getOrElse { "" })
            append(runCatching { Build.ID }.getOrElse { "" })
            append(runCatching { Build.MODEL }.getOrElse { "" })
            append(runCatching { Build.PRODUCT }.getOrElse { "" })
            append(runCatching { Build.SERIAL }.getOrElse { "" })
            toString()
        }.hash()
    }

}