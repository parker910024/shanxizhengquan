package ex.ss.lib.components.mmkv

class MMKVBuilder {

    fun setDefCryptKey(key: String) {
        MMKVManager.setDefCryptKey(key)
    }

    fun setCryptKey(name: String, key: String) {
        MMKVManager.setCryptKey(name, key)
    }

    fun setRootPath(path: String) {
        MMKVManager.setRootPath(path)
    }

}