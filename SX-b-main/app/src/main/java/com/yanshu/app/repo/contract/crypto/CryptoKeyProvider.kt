package com.yanshu.app.repo.contract.crypto

import com.yanshu.app.config.AppConfigCenter

object CryptoKeyProvider {
    private const val DEFAULT_FALLBACK_KEY = "123@abc"

    fun getMasterKey(): String {
        return AppConfigCenter.cryptoKey.ifEmpty { DEFAULT_FALLBACK_KEY }
    }
}
