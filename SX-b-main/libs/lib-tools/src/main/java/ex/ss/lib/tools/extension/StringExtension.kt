package ex.ss.lib.tools.extension

inline fun <C : CharSequence> C?.ifNullOrEmpty(defaultValue: () -> C): C {
    return if (this.isNullOrEmpty()) defaultValue.invoke() else this
}

fun <T : CharSequence> T.equalsTo(vararg equals: T, invoke: (item: T) -> T): T {
    for (item in equals) {
        if (item == this) return invoke.invoke(item)
    }
    return this
}

fun String?.isHttp(): Boolean {
    return if (this.isNullOrEmpty()) false else this.startsWith("http://")
}

fun String?.isHttps(): Boolean {
    return if (this.isNullOrEmpty()) false else this.startsWith("https://")
}