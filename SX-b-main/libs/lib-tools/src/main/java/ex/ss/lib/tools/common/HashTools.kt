package ex.ss.lib.tools.common

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.math.BigInteger
import java.security.DigestInputStream
import java.security.MessageDigest

object HashTools {

    fun hash(file: File, algorithm: String = "SHA-1"): String {
        val digest = MessageDigest.getInstance(algorithm)
        ByteArrayOutputStream().use { out ->
            DigestInputStream(FileInputStream(file), digest).use { input ->
                input.copyTo(out)
            }
        }
        return BigInteger(1, digest.digest()).toString(16)
    }

    fun hash(text: String, algorithm: String = "SHA-1"): String {
        return runCatching {
            val digest = MessageDigest.getInstance(algorithm)
            val byteArray = text.toByteArray(Charsets.UTF_8)
            byteArray.forEach { digest.update(it) }
            BigInteger(1, digest.digest()).toString(16)
        }.getOrElse { "" }
    }

    fun hash(byteArray: ByteArray, algorithm: String = "SHA-1"): String {
        return runCatching {
            val digest = MessageDigest.getInstance(algorithm)
            byteArray.forEach { digest.update(it) }
            BigInteger(1, digest.digest()).toString(16)
        }.getOrElse { "" }
    }

}

fun String.hash(algorithm: String = "SHA-1"): String {
    return HashTools.hash(this, algorithm)
}

fun File.hash(algorithm: String = "SHA-1"): String {
    return HashTools.hash(this, algorithm)
}

fun ByteArray.hash(algorithm: String = "SHA-1"): String {
    return HashTools.hash(this, algorithm)
}