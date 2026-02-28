package ex.ss.lib.components.mmkv

import com.tencent.mmkv.MMKV

abstract class IMMKVDelegate {

    private val mmkv by lazy {
        val crypt = MMKVManager.getCrypt(mmkvName())
        val rootPath = MMKVManager.getRootPath()
        val mode = if (openMultiProcessMode()) MMKV.MULTI_PROCESS_MODE else MMKV.SINGLE_PROCESS_MODE
        MMKV.mmkvWithID(mmkvName(), mode, crypt, rootPath)
    }

    abstract fun mmkvName(): String

    open fun openMultiProcessMode(): Boolean = false

    fun mmkv(): MMKV {
        return mmkv
    }

    fun clearAll() = mmkv.clearAll()

    fun allKeys() = mmkv.allKeys()

}