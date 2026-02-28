package ex.ss.lib.tools.extension


enum class TimeUnit(val value: Long) {
    MILL(1), SECOND(1000 * MILL.value), MINUTE(60 * SECOND.value), HOUR(60 * MINUTE.value), DAY(24 * HOUR.value);

    fun to(num: Int): Long {
        return value * num
    }

    fun to(num: Long): Long {
        return value * num
    }
}

val Long.SECOND: Long
    get() = TimeUnit.SECOND.to(this)
val Long.MINUTE: Long
    get() = TimeUnit.MINUTE.to(this)
val Long.HOUR: Long
    get() = TimeUnit.HOUR.to(this)
val Long.DAY: Long
    get() = TimeUnit.DAY.to(this)

val Int.SECOND: Long
    get() = TimeUnit.SECOND.to(this)
val Int.MINUTE: Long
    get() = TimeUnit.MINUTE.to(this)
val Int.HOUR: Long
    get() = TimeUnit.HOUR.to(this)
val Int.DAY: Long
    get() = TimeUnit.DAY.to(this)


fun Long.formatTime(unit: TimeUnit): Int {
    return this.formatTimeAndLess(unit).first
}

fun Long.formatTimeAndLess(unit: TimeUnit): Pair<Int, Long> {
    if (this < unit.value) return 0 to this
    val value = this / unit.value
    val less = this - value * unit.value
    return value.toInt() to less
}


fun Long.toTime(
    showHour: Boolean = true, showMinute: Boolean = true, showSecond: Boolean = true,
): String {
    if (showSecond && !showMinute && showHour) return "error"
    var lessTime = this
    val builder = StringBuilder()
    if (showHour) {
        val hour = lessTime / TimeUnit.HOUR.value
        lessTime = if (hour <= 0) {
            builder.append("00")
            lessTime
        } else {
            builder.append("$hour".padStart(2, '0'))
            lessTime - hour * TimeUnit.HOUR.value
        }
    }
    if (showMinute) {
        if (builder.isNotEmpty()) builder.append(":")
        val minute = lessTime / TimeUnit.MINUTE.value
        lessTime = if (minute <= 0) {
            builder.append("00")
            lessTime
        } else {
            builder.append("$minute".padStart(2, '0'))
            lessTime - minute * TimeUnit.MINUTE.value
        }
    }
    if (showSecond) {
        if (builder.isNotEmpty()) builder.append(":")
        val second = lessTime / TimeUnit.SECOND.value
        lessTime = if (second <= 0) {
            builder.append("00")
            lessTime
        } else {
            builder.append("$second".padStart(2, '0'))
            lessTime - second * TimeUnit.SECOND.value
        }
    }
    return builder.toString()
}
