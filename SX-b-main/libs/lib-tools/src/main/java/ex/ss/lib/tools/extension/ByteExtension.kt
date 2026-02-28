package ex.ss.lib.tools.extension

enum class ByteUnit(val value: Long, val unitName: String) {
    B(1L, "B"),
    KB(1024 * B.value, "KB"),
    MB(1024 * KB.value, "MB"),
    GB(1024 * MB.value, "GB"),
    TB(1024 * GB.value, "TB");

    fun to(num: Int): Long {
        return value * num
    }

    fun to(num: Long): Long {
        return value * num
    }
}

val Int.B: Long
    get() = ByteUnit.B.to(this)
val Int.KB: Long
    get() = ByteUnit.KB.to(this)
val Int.MB: Long
    get() = ByteUnit.MB.to(this)
val Int.GB: Long
    get() = ByteUnit.GB.to(this)
val Int.TB: Long
    get() = ByteUnit.TB.to(this)

val Long.B: Long
    get() = ByteUnit.B.to(this)
val Long.KB: Long
    get() = ByteUnit.KB.to(this)
val Long.MB: Long
    get() = ByteUnit.MB.to(this)
val Long.GB: Long
    get() = ByteUnit.GB.to(this)
val Long.TB: Long
    get() = ByteUnit.TB.to(this)


private fun findByteUnit(value: Long): ByteUnit? {
    return when {
        value >= ByteUnit.TB.value -> ByteUnit.TB
        value >= ByteUnit.GB.value -> ByteUnit.GB
        value >= ByteUnit.MB.value -> ByteUnit.MB
        value >= ByteUnit.KB.value -> ByteUnit.KB
        value >= ByteUnit.B.value -> ByteUnit.B
        else -> null
    }
}


fun Long.formatByteUnit(scale: Int = 2): String {
    val unit = findByteUnit(this) ?: return "$this"
    return "${(this * 1F / unit.value).formatScale(scale)}${unit.unitName}"
}

fun Int.formatByteUnit(scale: Int = 2): String {
    return this.toLong().formatByteUnit(scale)
}

fun Long.formatByte(scale: Int = 2): Pair<String, ByteUnit> {
    val unit = findByteUnit(this) ?: return "$this" to ByteUnit.B
    return (this * 1F / unit.value).formatScale(scale) to unit
}

fun Int.formatByte(scale: Int = 2): Pair<String, ByteUnit> {
    return this.toLong().formatByte(scale)
}

fun Long.formatByteUnit(unit: ByteUnit, scale: Int = 2): String {
    return "${(this * 1F / unit.value).formatScale(scale)}${unit.unitName}"
}

fun Int.formatByteUnit(unit: ByteUnit, scale: Int = 2): String {
    return this.toLong().formatByteUnit(unit, scale)
}

fun Long.formatByte(unit: ByteUnit, scale: Int = 2): String {
    return "${(this * 1F / unit.value).formatScale(scale)}${unit.unitName}"
}

fun Int.formatByte(unit: ByteUnit, scale: Int = 2): String {
    return this.toLong().formatByte(unit, scale)
}
