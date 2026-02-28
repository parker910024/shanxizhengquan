package com.yanshu.app.data

/**
 * 银证转入/转出记录接口 /api/user/capitalLog
 * type=0 转入 type=1 转出，不传为全部
 */
data class CapitalLogData(
    val list: List<CapitalLogItem>? = null,
    val userInfo: CapitalLogUserInfo? = null,
    val bank_list: List<CapitalLogBank>? = null,
    val kq_cancle: String? = null,
    val yhxy: String? = null,
)

data class CapitalLogItem(
    val id: Int = 0,
    val biz: String = "",
    val createtime: Long = 0L,
    val is_pay: String = "",
    val is_pay_name: String = "",
    val money: Double = 0.0,
    val pay_type_name: String = "",
    val reject: String = "",
    val txtcolor: String = "",
)

data class CapitalLogUserInfo(
    val balance: Double = 0.0,
    val freeze_profit: Double = 0.0,
)

data class CapitalLogBank(
    val id: Int = 0,
    val bankinfo: String = "",
    val tdname: String = "",
    val yzmima: String = "",
    val minlow: Int = 0,
    val maxhigh: Int = 0,
    val url_type: Int = 0,
)

data class RechargeRequest(
    val money: String,
    val sysbankid: Int,
    val pay_type: Int = 3,
)

data class RechargeResponse(
    val retCode: Int = -1,
    val retMsg: String = "",
    val payJumpUrl: String? = null,
)

/**
 * GET /api/index/getchargeconfignew
 */
data class ChargeConfigData(
    val charge_low: String = "",
    val contentmsg_gb: String = "",
    val is_sm: Int = 0,
    val min_tx_money: String = "",
    val sysbank_list: List<ChargeChannel>? = null,
)

/**
 * GET /api/index/getyhkconfignew
 */
data class YhkConfigData(
    val charge_low: String = "",
    val list: List<ChargeChannel>? = null,
    val tips: String = "",
)

data class ChargeChannel(
    val id: Int = 0,
    val bankinfo: String = "",
    val tdname: String = "",
    val yzmima: String = "",
    val minlow: Int = 0,
    val maxhigh: Int = 0,
    val url_type: Int = 0,
    val account: String = "",
)

