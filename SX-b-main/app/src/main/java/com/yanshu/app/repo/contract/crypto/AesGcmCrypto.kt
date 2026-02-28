package com.yanshu.app.repo.contract.crypto

import android.util.Base64
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object AesGcmCrypto {

    private const val GCM_IV_LENGTH = 12
    private const val GCM_TAG_LENGTH = 128

    fun decrypt(encryptedBase64: String): String {
        val encryptedBytes = decodeBase64Compat(encryptedBase64)
        if (encryptedBytes.size <= GCM_IV_LENGTH) {
            throw IllegalArgumentException("Encrypted data too short")
        }

        val iv = encryptedBytes.copyOfRange(0, GCM_IV_LENGTH)
        val ciphertextWithTag = encryptedBytes.copyOfRange(GCM_IV_LENGTH, encryptedBytes.size)

        val now = System.currentTimeMillis()
        val offsets = listOf(0L, -60_000L, 60_000L)
        val masterKey = CryptoKeyProvider.getMasterKey()

        for (offset in offsets) {
            try {
                val unixString = currentUnixString(now + offset)
                val key = deriveKey(masterKey, unixString)
                return decryptWithKey(ciphertextWithTag, iv, key)
            } catch (_: Exception) {
            }
        }
        throw IllegalStateException("Decryption failed with all time offsets")
    }

    fun encryptWithUnixString(plaintext: String, unixString: String): String {
        val key = deriveKey(CryptoKeyProvider.getMasterKey(), unixString)
        val iv = ByteArray(GCM_IV_LENGTH)
        java.security.SecureRandom().nextBytes(iv)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val keySpec = SecretKeySpec(key, "AES")
        val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec)

        val ciphertextWithTag = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        val result = iv + ciphertextWithTag
        return Base64.encodeToString(result, Base64.NO_WRAP)
    }

    private fun decryptWithKey(ciphertextWithTag: ByteArray, iv: ByteArray, key: ByteArray): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val keySpec = SecretKeySpec(key, "AES")
        val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec)
        val plaintext = cipher.doFinal(ciphertextWithTag)
        return String(plaintext, Charsets.UTF_8)
    }

    private fun deriveKey(masterKey: String, unixString: String): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        return digest.digest((masterKey + unixString).toByteArray(Charsets.UTF_8))
    }

    private fun decodeBase64Compat(base64Text: String): ByteArray {
        val normalized = base64Text.trim().replace("-", "+").replace("_", "/")
        val padding = (4 - normalized.length % 4) % 4
        val padded = normalized + "=".repeat(padding)
        return Base64.decode(padded, Base64.NO_WRAP)
    }

    fun currentUnixString(timeMillis: Long = System.currentTimeMillis()): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:00'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(timeMillis))
    }
}
