package com.yanshu.app.repo.contract.dynamic

data class DynamicConfig(
    val success: Boolean,
    val new: String,
    val key: String = "",
) {
    companion object {
        fun default(): DynamicConfig = DynamicConfig(false, "", "")
    }
}
