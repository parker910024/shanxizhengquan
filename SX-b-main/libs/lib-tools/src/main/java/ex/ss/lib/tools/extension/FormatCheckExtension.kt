package ex.ss.lib.tools.extension

fun String.isEmail(): Boolean {
    if (!this.contains("@")) return false
    if (!this.contains(".")) return false
    if (this.startsWith("@")) return false
    if (this.startsWith(".")) return false
    if (this.endsWith("@")) return false
    if (this.endsWith(".")) return false
    if (this.length < 4) return false
    if (this.lastIndexOf("@") > this.lastIndexOf(".")) return false
    return true
}