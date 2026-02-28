package ex.ss.lib.components.mmkv

import java.util.concurrent.atomic.AtomicReference

internal object MMKVManager {

    private val cryptKeyMap = mutableMapOf<String?, String>()
    private val rootPath = AtomicReference("")

    internal fun setRootPath(path: String) {
        rootPath.set(path)
    }

    internal fun setDefCryptKey(key: String) {
        setCryptKey(null, key)
    }

    internal fun setCryptKey(name: String?, key: String) {
        cryptKeyMap[name] = key
    }

    internal fun getCrypt(name: String? = null): String? {
        return if (cryptKeyMap.containsKey(name)) {
            cryptKeyMap[name]
        } else {
            cryptKeyMap[null]
        }
    }

    internal fun getRootPath(): String? {
        val path = rootPath.get()
        if (path.isNullOrEmpty()) return null
        return path
    }


}