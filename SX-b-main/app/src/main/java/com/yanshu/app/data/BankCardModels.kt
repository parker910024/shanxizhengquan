package com.yanshu.app.data

/**
 * 银行卡列表接口 POST /api/user/accountLst
 */
data class BankCardListResponse(
    val bindkanums: String = "0",
    val list: BankCardPageData = BankCardPageData(),
)

data class BankCardPageData(
    val current_page: Int = 1,
    val data: List<BankCardItem> = emptyList(),
    val last_page: Int = 1,
    val per_page: Int = 10,
    val total: Int = 0,
)

data class BankCardItem(
    val id: Int = 0,
    val user_id: Int = 0,
    val name: String = "",
    val account: String = "",
    val deposit_bank: String = "",
    val khzhihang: String = "",
    val createtime: Long = 0L,
) {
    val displayBankName: String get() = deposit_bank
    /** 银行卡号（完整展示，不脱敏） */
    val displayBankCard: String get() = account
}

/**
 * 绑定/编辑银行卡请求 POST /api/user/bindaccount
 */
data class BindBankCardRequest(
    val name: String,
    val deposit_bank: String,
    val account: String,
    val khzhihang: String,
    val id: Int? = null,
)
