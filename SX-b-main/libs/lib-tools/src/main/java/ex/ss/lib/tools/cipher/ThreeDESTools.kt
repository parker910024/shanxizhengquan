package ex.ss.lib.tools.cipher

import android.util.Base64
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

data class ThreeDESKeys(val key: String, val iv: String, val mode: Int = 0)

object ThreeDESTools {

    fun encryptFile(input: File, output: File, keys: ThreeDESKeys, deleteOrigin: Boolean = true) {
        val decrypt = keys.copy(mode = Cipher.ENCRYPT_MODE)
        cipherFile(input, output, decrypt)
        if (deleteOrigin) input.delete()
    }

    fun decryptFile(input: File, output: File, keys: ThreeDESKeys) {
        val decrypt = keys.copy(mode = Cipher.DECRYPT_MODE)
        cipherFile(input, output, decrypt)
    }

    private fun cipherFile(input: File, output: File, keys: ThreeDESKeys) {
        val eCipher = getDesedeCipher(keys.mode, keys.key, keys.iv)
        CipherInputStream(FileInputStream(input), eCipher).copyTo(FileOutputStream(output))
    }

    fun encryptString(input: String, keys: ThreeDESKeys): String {
        val bytes = input.toByteArray()
        val byteArray = encryptByteArray(bytes, keys)
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }

    fun decryptString(input: String, keys: ThreeDESKeys): String {
        val bytes = Base64.decode(input, Base64.DEFAULT)
        val byteArray = decryptByteArray(bytes, keys)
        return String(byteArray)
    }

    fun encryptByteArray(input: ByteArray, keys: ThreeDESKeys): ByteArray {
        val decrypt = keys.copy(mode = Cipher.ENCRYPT_MODE)
        return cipherByteArray(input, decrypt)
    }

    fun decryptByteArray(input: ByteArray, keys: ThreeDESKeys): ByteArray {
        val decrypt = keys.copy(mode = Cipher.DECRYPT_MODE)
        return cipherByteArray(input, decrypt)
    }


    private fun cipherByteArray(input: ByteArray, keys: ThreeDESKeys): ByteArray {
        val eCipher = getDesedeCipher(keys.mode, keys.key, keys.iv)
        val result = ByteArrayOutputStream()
        CipherInputStream(ByteArrayInputStream(input), eCipher).copyTo(result)
        return result.toByteArray()
    }

    private fun getDesedeCipher(opMode: Int, key: String, iv: String): Cipher {
        val keyByteArray = key.toByteArray(Charsets.UTF_8).copyInto(ByteArray(24))
        val secretKeySpec = SecretKeySpec(keyByteArray, "Desede")
        val ivParameterSpec = IvParameterSpec(iv.toByteArray(Charsets.UTF_8))
        return Cipher.getInstance("Desede/CBC/PKCS5Padding").apply {
            init(opMode, secretKeySpec, ivParameterSpec)
        }
    }

}