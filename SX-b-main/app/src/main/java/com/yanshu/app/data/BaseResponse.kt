package com.yanshu.app.data

data class BaseResponse<T>(
    val code: Int,    // 1成功 0失败 401登录失效
    val msg: String = "",
    val data: T,
    val time: String? = null,
) {
    // 兼容旧代码
    val message: String get() = msg

    companion object {
        const val FAILED = 0
        const val SUCCESS = 1
        const val EXPIRE = 401
    }
}