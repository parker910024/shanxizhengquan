package com.yanshu.app.repo.dynamic


data class DynamicConfig(
    val success: Boolean,
    val new: String,
) {
    companion object {
        fun default(): DynamicConfig {
            return DynamicConfig(false, "")
        }
    }
}