package ex.ss.lib.tools.extension

import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Locale

/*Format Number*/

fun Int.formatScale(scale: Int): String {
    if (scale < 0) return "$this"
    if (scale == 0) return "$this"
    return toDouble().formatScale(scale)
}

fun Long.formatScale(scale: Int): String {
    if (scale < 0) return "$this"
    if (scale == 0) return "$this"
    return toDouble().formatScale(scale)
}

fun Float.formatScale(scale: Int): String {
    if (scale < 0) return "$this"
    if (scale == 0) return "${this.toLong()}"
    return toDouble().formatScale(scale)
}

fun Double.formatScale(scale: Int): String {
    if (scale < 0) return "$this"
    if (scale == 0) return "${this.toLong()}"
    val pattern = "0.".padEnd(scale + 2, '0')
    return DecimalFormat(pattern).format(this)
}

/*Format Money*/

fun Int.formatMoney(format: Int = 1, scale: Int = 2): String {
    return (this.toDouble() / format).formatScale(scale)
}

fun Long.formatMoney(format: Int = 1, scale: Int = 2): String {
    return (this.toDouble() / format).formatScale(scale)
}

fun Int.formatCent(format: Int = 100, scale: Int = 2): String {
    return (this.toDouble() / format).formatScale(scale)
}

fun Long.formatCent(format: Int = 100, scale: Int = 2): String {
    return (this.toDouble() / format).formatScale(scale)
}


/*Format Date*/

private val dataFormat by lazy { SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()) }

fun Long.formatDate(pattern: String = "", defaultValue: String = "--"): String {
    if (this < 0) return defaultValue
    if (pattern.isEmpty()) {
        return dataFormat.format(this)
    }
    return SimpleDateFormat(pattern, Locale.getDefault()).format(this)
}

fun Int.formatDate(pattern: String = "", defaultValue: String = "--"): String {
    return this.toLong().formatDate(pattern, defaultValue)
}

fun Long.formatSecondDate(pattern: String = "", defaultValue: String = "--"): String {
    if (this < 0) return defaultValue
    if (pattern.isEmpty()) {
        return dataFormat.format(this * 1000)
    }
    return SimpleDateFormat(pattern, Locale.getDefault()).format(this * 1000)
}

fun Int.formatSecondDate(pattern: String = "", defaultValue: String = "--"): String {
    return this.toLong().formatSecondDate(pattern, defaultValue)
}