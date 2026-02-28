package com.yanshu.app.data

/**
 * Login request.
 */
data class LoginRequest(
    val account: String,
    val password: String,
)

/**
 * Register request.
 * mobile 字段统一传递账号（手机号或用户名，由 REGISTER_TYPE 决定）
 */
data class RegisterRequest(
    val mobile: String,
    val password: String,
    val payment_code: String = "",
    val institution_number: String = "",
)


data class BuyOfflinePlacementRequest(
    val code: String,
    val sg_nums: Int,
    val miyao: String = "",
)

data class BuyBlockTradeRequest(
    val allcode: String,
    val canBuy: Int,
    val miyao: String = "",
)

/** 股票买入（文档 3.23）POST api/deal/addStrategy */
data class AddStrategyRequest(
    val allcode: String,
    val buyprice: Double,
    val canBuy: Int,
)

/** 添加/取消自选（文档 3.20/3.21）POST api/ask/addzx | api/ask/delzx */
data class FavoriteRequest(
    val allcode: String,
    val code: String,
)

/** 股票卖出（平仓）兼容旧后端 POST body 参数 */
data class SellStockRequest(
    val id: Int,
    val sellprice: Double,
    val number: Int,
)

/** 股票卖出（H5 当前实现）POST api/deal/sell */
data class SellRequest(
    val id: Int,
    val allcode: String,
    val canBuy: Int,
    val waystatus: Int = 1,
    val sellprice: Double,
)

/** 新股申购（文档 3.22）POST api/subscribe/add */
data class SubscribeIpoRequest(
    val code: String,
)

/** 新股申购认缴（文档 3.27）POST api/subscribe/renjiao_act */
data class RenjiaoRequest(
    val id: Int,
)
