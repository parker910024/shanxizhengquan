package com.yanshu.app.repo.contract.crypto

data class CryptoContext(
    val unixString: String,
    val originalPath: String,
    val originalMethod: String,
    val originalQuery: Map<String, String>,
)
