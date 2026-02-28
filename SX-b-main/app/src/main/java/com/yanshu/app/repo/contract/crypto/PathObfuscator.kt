package com.yanshu.app.repo.contract.crypto

import kotlin.random.Random

object PathObfuscator {

    private val charPool = ('a'..'z') + ('0'..'9')

    fun confusePath(path: String): String {
        if (path.isEmpty()) return path
        val segments = path.split("/")
        return segments.joinToString("/") { segment ->
            if (segment.isEmpty()) segment else obfuscateSegment(segment)
        }
    }

    private fun obfuscateSegment(segment: String): String {
        val len = segment.length
        val left = (len + 1) / 2
        val right = len - left
        return generateRandomString(left) + segment + generateRandomString(right)
    }

    private fun generateRandomString(length: Int): String {
        if (length <= 0) return ""
        return buildString(length) {
            repeat(length) {
                append(charPool[Random.nextInt(charPool.size)])
            }
        }
    }
}
