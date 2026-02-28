package com.yanshu.app.data

data class LoginApiData(
    val userinfo: UserInfoData = UserInfoData(),
)

data class UserInfoData(
    val id: Int = 0,
    val user_id: Int = 0,
    val username: String = "",
    val mobile: String = "",
    val nickname: String = "",
    val avatar: String = "",
    val token: String = "",
    val createtime: Long = 0,
    val expires_in: Long = 0,
    val expiretime: Long = 0,
)

data class UserProfileData(
    val list: UserProfile = UserProfile(),
)

data class UserProfile(
    val id: Int = 0,
    val username: String = "",
    val mobile: String = "",
    val nickname: String = "",
    val avatar: String = "",
    val balance: Double = 0.0,
    val money: Double = 0.0,
    val freeze_money: String = "",
    val freeze_profit: Double = 0.0,
    val property_money: Double = 0.0,
    val is_auth: Int = 0,
    val is_authentication: String = "",
    val is_card: Int = 0,
    val is_cash: Int = 1,
    val is_recharge: Int = 1,
    val is_dz: Int = 1,
    val is_ps: Int = 1,
    val is_sg: Int = 1,
    val isContract: String = "1",
    val isEditBuy: String = "1",
    val jingzhijiaoyi: String = "0",
    val status: String = "normal",
    val xx_num: Int = 0,
    val logintime: Long = 0L,
    val loginip: String = "",
    val createtime: Long = 0L,
)

// Real-name authentication detail: GET /api/user/authenticationDetail
data class AuthenticationDetailData(
    val detail: AuthenticationDetailItem? = null,
)

data class AuthenticationDetailItem(
    val id: Int = 0,
    val user_id: Int = 0,
    val name: String = "",
    val id_card: String = "",
    val frontcardimage: String = "",
    val backcardimage: String = "",
    val is_audit: String = "", // 0=pending, 1=approved, 2=rejected, 3=reviewing
    val reject: String = "",
    val auth_contact: String = "",
) {
    val hasSubmitted: Boolean
        get() = name.isNotBlank() || id_card.isNotBlank()

    val isApproved: Boolean
        get() = is_audit == "1"

    val isRejected: Boolean
        get() = is_audit == "2"

    // Align with SX: only treat 0/3 as pending after user has submitted real-name info.
    val isPending: Boolean
        get() = hasSubmitted && (is_audit == "0" || is_audit == "3")
}

// Submit real-name authentication: POST /api/user/authentication
data class AuthenticationRequest(
    val name: String,
    val id_card: String,
    val f: String, // front image path
    val b: String, // back image path
)

// Global config: GET /api/stock/getconfig (doc 1.2)
data class AppConfigData(
    val kf_url: String = "",
    val dz_syname: String = "",    // block-trade display name
    val is_xxps_name: String = "", // offline placement display name
    val is_xgsg_name: String = "", // IPO display name
    val mai_fee: String = "0.0001",
    val maic_fee: String = "0.0001",
    val yh_fee: String = "0.0003",
)

// Upload config: POST /api/user/getAlicloudSTS (doc 1.3)
data class AliCloudStsData(
    val endpoint: String = "",
    val bucket: String = "",
    val upload_type: String = "0",
)

// Asset (trade page): GET /api/user/getUserPrice_all1
data class UserPriceAll1Data(
    val list: UserPriceAll1Item = UserPriceAll1Item(),
)

data class UserPriceAll1Item(
    val balance: Double = 0.0,
    val city_value: Double = 0.0,
    val fdyk: Double = 0.0,
    val freeze_profit: Double = 0.0,
    val property_money_total: Double = 0.0,
    val totalyk: Double = 0.0,
    val weituozj: Double = 0.0,
)

// Asset (user page): GET /api/user/getUserPrice_all
data class UserPriceAllData(
    val list: UserPriceAllItem = UserPriceAllItem(),
)

data class UserPriceAllItem(
    val balance: Double = 0.0,
    val city_value: Double = 0.0,
    val fdyk: Double = 0.0,
    val freeze_profit: Double = 0.0,
    val property_money_total: Double = 0.0,
    val totalyk: Double = 0.0,
    val xingu_total: Double = 0.0,
)
