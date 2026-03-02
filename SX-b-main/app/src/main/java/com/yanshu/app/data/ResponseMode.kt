package com.yanshu.app.data

import com.google.gson.annotations.SerializedName
import com.yanshu.app.BuildConfig
import java.io.Serializable


data class BooleanResponse(val data: Boolean)
data class StringResponse(val data: String)

data class LoginData(
    val token: String, val auth_data: String,
)

data class UserInfo(
    val tel: String, //手机号 为空则为游客
    val id: Int, //用户id
    val plan_id: Int, //1：vip 2:svip 3：免费 4:普通用户
    val svip_time: Long, //过期时间
    val vip_time: Long, //过期时间
    val free_time: Long, //过期时间
    val is_receive_free: Int, //五分钟免费vip领取状态： 1：未领取 2：已领取
    val vip_remark: String, //用户身份 备注
    val recharge_status: Int, //是否充值： 1:充值过 2：未充值过
    val bind_invite_code: String, //绑定的邀请码 没有则为空
)

data class MineConfig(
    val kefu: String?, //客服设置
    val livechat: String?, //livechat客服设置
    val crisp: String?, //livechat客服设置
    val xieyi: String?, //服务协议链接
    val yinsi: String?, //隐私政策链接
    val zhuxiao: String?, //隐私政策链接
    val bangzhu: String?, //在线帮助
    val contact_email: String?, //联系邮箱
    val website: String?, //网站地址
    val app_application: String?, //应用推荐
    val telegram: String?, //TG交流群
)

data class VersionInfo(
    val create_time: String,
    val describe: String,
    val device: Int,
    val dow_address: String,
    val id: Int,
    val renew: Int, //是否强制更新 1：是 2：否
    val update_time: String,
    val version: String,
) {

    fun hasNewVersion(): Boolean { //1.1.9 - 1.2.0
        //10109 - 10200
        return runCatching {
            convertVersion(version) > convertVersion(BuildConfig.VERSION_NAME)
        }.getOrElse {
            version != BuildConfig.VERSION_NAME
        }
    }

    //1.0 => 10000
    //1.0.1 => 10001
    //1.0.0.1 => 10000
    private fun convertVersion(ver: String): Int {
        return when {
            ver.length == 5 -> ver
            ver.length < 5 -> ver.padEnd(5, '.')
            ver.length > 5 -> ver.substring(0, 5)
            else -> "....."
        }.let { it.replace(".", "0").toInt() }
    }

    fun isForce(): Boolean {
        return renew == 1
    }
}

// ==================== 线下配售（战略配售）====================

/** 配售/新股可申购列表 - /api/subscribe/xxlst 和 /api/subscribe/lst */
data class IPOListData(
    val list: List<IPOGroup> = emptyList(),
    val maxxg: Int = 0,
)

data class IPOGroup(
    val flag: Int = 0,
    val sub_info: List<IPOItem> = emptyList(),
)

data class IPOItem(
    val id: Int,
    val code: String = "",          // 股票代码
    val name: String = "",          // 股票名称
    val sgcode: String = "",        // 申购代码
    val fx_num: String = "0",       // 发行数量
    val wsfx_num: String = "0",     // 网上发行
    val sg_limit: String = "0",     // 申购上限
    val fx_price: String = "0",     // 发行价格
    val fx_rate: String = "0",      // 发行市盈率
    val sg_date: String = "",       // 申购日期
    val zq_rate: String = "0",      // 中签率
    val ss_date: String = "",       // 上市日期
    val sgswitch: Int = 0,          // 申购开关 0关闭 1开启
    val xxswitch: Int = 0,          // 线下配售开关 0关闭 1开启
    val content: String = "",       // 申购秘钥
    val sg_type: String = "1",      // 1沪 2深 3创 5科 4京
    val industry: String = "",      // 所属行业
    val sg_type_text: String = "",   // 板块文案 如北交所
) : Serializable {
    fun getMarketTag(): String = when (sg_type ?: "") {
        "1" -> "沪"; "2" -> "深"; "3" -> "创"; "4" -> "京"; "5" -> "科"; else -> ""
    }

    /** 所属板块展示：优先 sg_type_text，否则按 sg_type 映射；空安全避免 Gson 反序列化 null */
    fun getMarketText(): String = (sg_type_text ?: "").ifEmpty {
        when (sg_type ?: "") {
            "1" -> "沪市"; "2" -> "深市"; "3" -> "创业板"; "4" -> "北交所"; "5" -> "科创板"
            else -> ""
        }
    }
}

/** 配售详情 - /api/subscribe/lstDetail */
data class PlacementDetailData(
    val info: PlacementDetailInfo = PlacementDetailInfo(),
    val kqssss: Int = 0,
    val maxxg: Int = 0,
    val psjy0_ss: Int = 0,
    val psmax: String = "10000000",
)

data class PlacementDetailInfo(
    val id: Int = 0,
    val code: String = "",
    val name: String = "",
    val sgcode: String = "",
    val fx_num: String = "0",
    val wsfx_num: String = "0",
    val sg_limit: String = "0",
    val fx_price: String = "0",
    val fx_rate: String = "0",
    val sg_date: String = "",
    val zq_rate: String = "0",
    val ss_date: String = "",
    val content: String = "",
    val sg_type: String = "1",
    val sg_type_text: String = "",
    val industry: String = "",
) : Serializable {
    fun getMarketText(): String = when (sg_type) {
        "1" -> "沪市"; "2" -> "深市"; "3" -> "创业板"; "4" -> "北交所"; "5" -> "科创板"
        else -> sg_type_text.ifEmpty { "未知" }
    }
}

/** 配售记录 - /api/subscribe/getsgnewgu，data.dxlog_list */
data class MyPlacementListData(
    val dxlog_list: List<MyPlacementItem> = emptyList(),
)

/** 配售记录单项：申购中/中签/未中签列表 */
data class MyPlacementItem(
    val id: Int = 0,
    val code: String = "",
    val name: String = "",
    val sg_fx_price: Double = 0.0,   // 发行价
    val sg_num: Int = 0,             // 申购手数
    val sg_nums: Int = 0,            // 申购数量(股)
    val status: String = "0",        // 0申购中 1中签 2未中签
    val money: String = "0",         // 占用金额
    val zq_num: Int = 0,             // 中签数量(股)，数量(股)展示用
    val zq_nums: Int = 0,
    val status_txt: String = "",     // 如 申购中5(手)、中签5(手)
    val sg_ss_date: String = "",     // 上市时间
    val createtime_txt: String = "", // 日期 如 2026-02-28
    val dj_money: Double = 0.0,      // 冻结/占用金额
) : Serializable

// ==================== 新股申购记录 ====================

/** 已申购新股列表 - /api/subscribe/getsgnewgu0 */
data class MyIpoListData(
    val dxlog_list: List<MyIpoItem> = emptyList(),
)

data class MyIpoItem(
    val id: Int = 0,
    val code: String = "",
    val name: String = "",
    val sg_fx_price: Double = 0.0,   // 发行价
    val status: String = "0",        // 0申购中 1中签 2未中签 3弃购
    val zq_num: Int = 0,             // 中签数量(股)
    val zq_nums: Int = 0,            // 中签数量(手)
    val renjiao: String = "0",       // 是否认缴 0未认缴 1已认缴
    val is_cc: String = "0",         // 是否转持仓
    val zq_money: Double = 0.0,      // 中签金额
    val sy_renjiao: Double = 0.0,    // 剩余认缴金额（后端扩展字段）
    val status_txt: String = "",     // 状态文本
    val sg_ss_date: String = "",     // 上市时间
    val sg_ss_tag: Int = 0,          // 是否有上市时间
    val createtime_txt: String = "", // 日期文本
) : Serializable

/** 中签未认缴数据 - /api/stock/ballot */
data class BallotData(
    val count: Int = 0,
    val info: List<MyIpoItem> = emptyList(),
)

// ==================== 大宗交易（天启护盘）====================

// ==================== 行情 ====================

/** 股票自选状态（文档 3.19）/api/Indexnew/getHqinfo_1 */
data class HqInfoData(
    val is_zq: Int = 0,     // 是否实名 0未实名 1已实名
    val is_zx: Int = 0,     // 是否加入自选 0否 1是
)

/** 指数行情列表 - /api/Indexnew/sandahangqing_new（文档 3.8） */
data class IndexMarketData(
    val list: List<IndexMarketItem> = emptyList(),
)

data class IndexMarketItem(
    val title: String = "",
    val code: String = "",
    val allcode: String = "",                       // 如 sh000001，前缀决定市场
    val allcodes_arr: List<String> = emptyList(),
    // allcodes_arr 各位索引含义：
    // [0]=市场标识(1=沪/51=深) [1]=名称 [2]=代码
    // [3]=最新价 [4]=涨跌额 [5]=涨跌幅(%) [10]=类型(ZS=指数)
)

/** 股票列表 - 沪深/创业/北证/科创格式相同（文档 3.15-3.18） */
data class StockListWrapData(
    val list: List<StockListItem> = emptyList(),
)

data class StockListItem(
    val code: String = "",
    val name: String = "",
    val symbol: String = "",            // 完整代码如 sh688108
    val trade: String = "",             // 当前价
    val pricechange: String = "",       // 涨跌额
    val changepercent: String = "",     // 涨跌幅(%)
    val buy: String = "",               // 成交量
    val open: String = "",              // 开盘价
    val settlement: String = "",        // 昨收
    val sell: String = "",              // 外盘
)

/** 大宗交易列表 - /api/dzjy/lst（balance/max_num 兼容后端返回数字或字符串，与 iOS 一致） */
data class BlockTradeListData(
    val list: List<BlockTradeItem> = emptyList(),
    @SerializedName("balance") val balanceRaw: Any? = null,
) {
    /** 可用余额，兼容 API 返回 number 或 string */
    fun getBalanceDouble(): Double = when (balanceRaw) {
        is Number -> balanceRaw.toDouble()
        is String -> balanceRaw.toDoubleOrNull() ?: 0.0
        else -> 0.0
    }
}

data class BlockTradeItem(
    val id: Int,
    val title: String = "",         // 股票名称
    val code: String = "",          // 股票代码
    val allcode: String = "",       // 完整代码 如 sh688805
    val cai_buy: String = "0",      // 增发价格
    val cai_price: String = "0",    // 当前价格
    val status: String = "0",       // 0开启 1关闭
    val type: Int = 1,              // 1沪 2深 3创业 4北交 5科创 6基金
    @SerializedName("max_num") val max_num_raw: Any? = null,  // 最大可购买手数，兼容 number/string
    val rate: Double = 0.0,         // 价格比例(%)
    val zfanum: Int = 0,            // 增发数量万起
    val totalbuy: Int = 0,          // 已增发数量
    val pingday: Int = 1,           // 增发平仓天数
    val is_dz: Int = 0,             // 开启大宗交易
    val is_zfa: Int = 0,            // 开启增发交易
) : Serializable {
    /** 最大可买(手)，兼容 API 返回 number 或 string，与 iOS 一致 */
    fun maxNumInt(): Int = when (max_num_raw) {
        is Number -> max_num_raw.toInt()
        is String -> max_num_raw.toIntOrNull() ?: 0
        else -> 0
    }
    /** 与 API 文档及其他端一致：北交所(type=4) 显示「京」 */
    fun getMarketTag(): String = when (type) {
        1 -> "沪"; 2 -> "深"; 3 -> "创"; 4 -> "京"; 5 -> "科"; 6 -> "基"; else -> ""
    }
}

/** 大宗交易持仓 - /api/dzjy/getNowWarehouse */
data class HoldingListData(
    val list: List<HoldingItem> = emptyList(),
    val position_money: Double = 0.0,       // 持仓盈亏
    val total_city_value: Double = 0.0,     // 总市值
)

data class HoldingItem(
    val id: Int = 0,
    val code: String = "",
    val allcode: String = "",
    val title: String = "",           // 股票名称
    val type: Int = 1,                // 1沪 2深 3创业 4北交 5科创 6基金
    val buyprice: Double = 0.0,       // 买入价格（API 可能为 number）
    val cai_buy: Any? = null,         // 当前/卖出价，API 可能为 string 或 number
    val canBuy: String = "",          // 手数
    val number: String = "",          // 股数
    val money: String = "",           // 占用金额
    val citycc: Double = 0.0,         // 本金/市值（部分接口返回）
    @SerializedName("cityValue")
    val cityValueRaw: Any? = null,    // 本金/市值（部分接口返回，可能为 ""）
    val profitLose: Any? = null,      // 盈亏，API 可能为 string 或 number
    val profitLose_rate: String = "", // 盈亏比例
    val allMoney: String = "",        // 手续费
    val createtime_name: String = "", // 买入时间
    val outtime_name: String = "",    // 卖出时间
    val yhfee: String = "",           // 印花税
    // 委托列表（3.29）额外字段
    val buytype: String = "",         // 交易类型 1普通 7增发(大宗)
    val cjlx: String = "",            // 状态描述 如挂单
    val creditMoney: Double = 0.0,
    val status: Int = 0,             // 1当前持仓 2当前委托 3历史交易 4已撤单
    val multiplying: String = "",     // 委托倍数（Web entrustDetail 字段，服务端若返回则使用）
) : Serializable {
    /** 本金/市值：兼容 citycc 与 cityValue(number/string/"") */
    fun cityValueDouble(): Double {
        if (citycc > 0) return citycc
        return when (cityValueRaw) {
            is Number -> cityValueRaw.toDouble()
            is String -> cityValueRaw.toDoubleOrNull() ?: 0.0
            else -> 0.0
        }
    }

    /** 当前价/卖出价，兼容 API 返回 string 或 number */
    fun caiBuyDouble(): Double = when (cai_buy) {
        is Number -> (cai_buy as Number).toDouble()
        is String -> (cai_buy as String).toDoubleOrNull() ?: 0.0
        else -> 0.0
    }
    /** 盈亏，兼容 API 返回 string 或 number */
    fun profitLoseDouble(): Double = when (profitLose) {
        is Number -> (profitLose as Number).toDouble()
        is String -> (profitLose as String).toDoubleOrNull() ?: 0.0
        else -> 0.0
    }
}

/** 卖出用持仓项 - /api/deal/mrSellLst（文档 3.32） */
data class MrSellItem(
    val id: Int = 0,
    val code: String = "",
    val allcode: String = "",
    val title: String = "",
    val canBuy: String = "",
    val buyprice: String = "",
    val number: String = "",
    val type: Int = 1,
)

/** 股票搜索结果（后端 api/user/searchstrategy） */
data class StockSearchApiData(
    val list: List<StockSearchApiItem> = emptyList(),
)

data class StockSearchApiItem(
    val code: String = "",       // 纯代码，如 "000001"
    val name: String = "",       // 股票名称
    val allcode: String = "",    // 完整代码，如 "sz000001"
    val type: Int = 1,           // 1沪 2深 3创业 4北交 5科创 6基金
    val latter: String = "",     // 简拼
    val cai_buy: String = "",    // 后端返回的价格字段（字符串）
    val zfrate: Double = 0.0,    // 后端返回的涨跌幅字段（百分比）
)
