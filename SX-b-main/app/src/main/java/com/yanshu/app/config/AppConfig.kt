package com.proxy.base.config

import com.yanshu.app.BuildConfig
import ex.ss.lib.components.mmkv.IMMKVDelegate
import ex.ss.lib.components.mmkv.kvDelegate

object AppConfig : IMMKVDelegate() {
    override fun mmkvName(): String = "appConfig"

    var deviceId by kvDelegate("")
    var channel by kvDelegate("")
    var oaid by kvDelegate("")
    var oaidRequestTimes by kvDelegate(0)

    var dynamicDomain by kvDelegate("")
    var dynamicKey by kvDelegate("")

    var inviteCode by kvDelegate("")
    var netLock by kvDelegate(false)

    var lastShowMarketRedDotTime by kvDelegate(0L)
    var enableCryptoLog by kvDelegate(BuildConfig.ENABLE_CRYPTO_LOG)

}
