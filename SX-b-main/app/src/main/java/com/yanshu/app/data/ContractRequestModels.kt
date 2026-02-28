package com.yanshu.app.data

data class CreateContractRequest(
    val type: Int,
    val address: String,
    val name: String = "",
    val idnumber: String = "",
)

data class SignContractRequest(
    val id: String,
    val img: String,
)

/** 验证支付密码请求（/api/user/checkOldpay） */
data class CheckPayPasswordRequest(val paypass: String)

/** 修改支付密码请求（/api/user/editPass），仅传新密码 */
data class EditPayPasswordRequest(val password: String)

/** 修改登录密码请求（/api/user/editPass1） */
data class EditLoginPasswordRequest(
    val oldpass: String,
    val password: String,
    val confimpassword: String,
)
