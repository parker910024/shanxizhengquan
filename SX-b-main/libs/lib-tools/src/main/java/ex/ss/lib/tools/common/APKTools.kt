package ex.ss.lib.tools.common

import android.content.Context
import android.content.pm.PackageManager
import java.math.BigInteger
import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicReference

object APKTools {

    private val signNature = AtomicReference("")

    fun getSignNature(context: Context): String {
        if (!signNature.get().isNullOrEmpty()) return signNature.get()
        return signatureString(context)?.apply {
            signNature.set(this)
        } ?: ""
    }

    private fun signatureString(context: Context, algorithm: String = "SHA-256"): String? =
        runCatching {
            context.packageManager.getPackageInfo(
                context.packageName, PackageManager.GET_SIGNATURES
            ).signatures[0].toByteArray().let { MessageDigest.getInstance(algorithm).digest(it) }
                .let { BigInteger(1, it).toString(16) }
        }.getOrNull()

}