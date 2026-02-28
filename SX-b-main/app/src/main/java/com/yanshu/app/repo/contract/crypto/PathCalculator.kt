package com.yanshu.app.repo.contract.crypto

import java.security.MessageDigest

object PathCalculator {

    fun calculatePath(key: String, unixString: String): String {
        val seed = key + unixString
        val hashBytes = sha256Bytes(seed)
        val hashHex = sha256Hex(hashBytes)

        var segmentsCount = (hashBytes[0].toInt() and 0xff) % 4
        if (segmentsCount == 0) segmentsCount = 4

        val parts = mutableListOf<String>()
        for (i in 1..segmentsCount) {
            var k = (hashBytes[i].toInt() and 0xff) % 5
            if (k == 0) k = 5
            val start = i * 10
            parts += hashHex.substring(start, start + k)
        }
        return "/" + parts.joinToString("/")
    }

    private fun sha256Bytes(text: String): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        return digest.digest(text.toByteArray(Charsets.UTF_8))
    }

    private fun sha256Hex(bytes: ByteArray): String {
        val sb = StringBuilder(bytes.size * 2)
        for (b in bytes) {
            sb.append(String.format("%02x", b))
        }
        return sb.toString()
    }
}
