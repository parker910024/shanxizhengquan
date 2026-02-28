package com.yanshu.app.config

import com.proxy.base.config.AppConfig
import com.yanshu.app.BuildConfig

/**
 * Unified runtime config access for contract crypto/domain logic.
 */
object AppConfigCenter {

    private const val DEFAULT_CRYPTO_KEY = "123@abc"

    val baseUrl: String
        get() = BuildConfig.BASE_URL

    val imageBaseUrl: String
        get() = BuildConfig.IMAGE_BASE_URL

    val baseDomain: String
        get() = AppConfig.dynamicDomain.ifEmpty { BuildConfig.BASE_URL }

    val cryptoKey: String
        get() = AppConfig.dynamicKey.ifEmpty { DEFAULT_CRYPTO_KEY }

    var enableCryptoLog: Boolean
        get() = AppConfig.enableCryptoLog
        set(value) {
            AppConfig.enableCryptoLog = value
        }

    val isPhoneRegisterMode: Boolean
        get() = BuildConfig.REGISTER_TYPE == "2"

    val isUsernameRegisterMode: Boolean
        get() = BuildConfig.REGISTER_TYPE == "1"
}
