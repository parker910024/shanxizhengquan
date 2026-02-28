package ex.ss.lib.components

import android.content.Context
import com.tencent.mmkv.MMKV
import ex.ss.lib.components.mmkv.MMKVBuilder

object SSComponents {

    fun initialize(context: Context) {
        MMKV.initialize(context)
    }

    fun initMMKV(builder: MMKVBuilder.() -> Unit = {}) {
        MMKVBuilder().apply(builder)
    }

}