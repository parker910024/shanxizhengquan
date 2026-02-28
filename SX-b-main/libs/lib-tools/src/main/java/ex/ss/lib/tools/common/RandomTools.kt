package ex.ss.lib.tools.common

object RandomTools {

    private const val ENGLISH_TEXT = "abcdefghijklmnopqrstuvwxyz"
    private const val INT_TEXT = "0123456789"

    fun randomEngineCode(length: Int): String = runCatching {
        return random(ENGLISH_TEXT, length)
    }.getOrElse { "" }

    fun randomInt(length: Int): Int = runCatching {
        return random(INT_TEXT, length).toInt()
    }.getOrElse { 0 }

    fun random(seed: String, length: Int = seed.length): String {
        if (seed.isEmpty()) return ""
        return with(StringBuilder()) {
            repeat(length) {
                val index = (Math.random() * seed.length).toInt()
                append(seed[index].toString())
            }
        }.toString()
    }

}
