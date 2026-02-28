package com.yanshu.app.repo

import android.util.Log
import com.yanshu.app.ui.dragon.DragonItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

/**
 * 东方财富 龙虎榜 数据（独立 OkHttp，不走后端加密）
 * 接口：datacenter-web.eastmoney.com 每日龙虎榜个股列表
 */
object EastMoneyDragonRepository {

    private const val TAG = "EastMoneyDragon"
    private const val BASE_URL = "https://datacenter-web.eastmoney.com/api/data/v1/get"

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    // 抓包结果：tradedetail.html 使用 sortColumns=SECURITY_CODE,TRADE_DATE sortTypes=1,-1 pageSize=50
    private val REPORT_NAMES = listOf(
        "RPT_DAILYBILLBOARD_DETAILS",  // 每日龙虎榜详情（抓包确认）
        "RPT_DAILYBILLBOARD",
        "RPT_BILLBOARD_DAILY",
        "RPT_BLOCKOPERATION"
    )

    /**
     * 按日期获取龙虎榜列表（东方财富数据中心）
     * 抓包验证：RPT_DAILYBILLBOARD_DETAILS 需用 TRADE_DATE<='日期' 才有数据
     * @param date 格式 yyyy-MM-dd
     */
    suspend fun getListByDate(date: String): Result<List<DragonItem>> = withContext(Dispatchers.IO) {
        var lastError: Throwable? = null
        val filters = listOf(
            "(TRADE_DATE<='$date')",           // 每日龙虎榜详情接口实际支持的写法
            "(TRADE_DATE='$date')",
            "(ONLIST_DATE>='$date')",
            "(TRADE_DATE='${date.replace("-", "")}')"
        )
        for (reportName in REPORT_NAMES) {
            for (filter in filters) {
                val res = fetchWithFilter(date, reportName, filter)
                if (res.isSuccess) {
                    val list = res.getOrNull() ?: emptyList()
                    if (list.isNotEmpty()) {
                        // 只保留请求日当天的
                        val sameDay = list.filter { item -> item.tradeDate?.startsWith(date) == true }
                        val dayList = if (sameDay.isNotEmpty()) sameDay else list
                        // 同一只股票可能因多种上榜原因出现多条，按代码去重，保留净买入绝对值最大的一条
                        val deduped = dayList.groupBy { it.code }
                            .mapNotNull { (_, items) -> items.maxByOrNull { kotlin.math.abs(it.netBuy) } }
                        return@withContext Result.success(deduped)
                    }
                } else {
                    lastError = res.exceptionOrNull()
                }
            }
        }
        lastError?.let { Result.failure(it) } ?: Result.success(emptyList())
    }

    private fun fetchWithReport(date: String, reportName: String): Result<List<DragonItem>> =
        fetchWithFilter(date, reportName, "(TRADE_DATE='$date')")

    private fun fetchWithFilter(date: String, reportName: String, filter: String): Result<List<DragonItem>> = runCatching {
        // 东方财富 filter 支持 TRADE_DATE / ONLIST_DATE，格式 yyyy-MM-dd 或 yyyyMMdd
        val url = "$BASE_URL?" +
            "sortColumns=SECURITY_CODE,TRADE_DATE" +
            "&sortTypes=1,-1" +
            "&pageSize=500" +
            "&pageNumber=1" +
            "&reportName=$reportName" +
            "&columns=ALL" +
            "&source=WEB" +
            "&client=WEB" +
            "&filter=${URLEncoder.encode(filter, "UTF-8")}"
        parseAndRequest(url)
    }.onFailure { e -> Log.w(TAG, "fetch reportName=$reportName filter=$filter", e) }

    private fun parseAndRequest(url: String): List<DragonItem> {
        val proxyUrl = com.yanshu.app.repo.eastmoney.EastMoneyMarketRepository.PROXY_BASE_URL
        val actualUrl = if (proxyUrl.isNotEmpty()) {
            "$proxyUrl/proxy?url=${java.net.URLEncoder.encode(url, "UTF-8")}"
        } else {
            url
        }
        val request = Request.Builder()
            .url(actualUrl)
            .header("User-Agent", "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36")
            .header("Referer", "https://data.eastmoney.com/")
            .get()
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) throw Exception("HTTP ${response.code}")
        val body = response.body?.string() ?: throw Exception("empty body")
        return parseResponse(body, "")
    }

    /**
     * 解析东方财富 datacenter API 返回
     * 常见结构: { "success": true, "result": { "data": [...], "total": n } } 或 { "data": [...] }
     * 无数据或 reportName 错误时可能返回 result: null，需安全解析
     */
    private fun parseResponse(json: String, date: String): List<DragonItem> {
        val root = runCatching { JSONObject(json) }.getOrNull() ?: return emptyList()
        val dataArray = when {
            root.has("result") -> {
                val result = root.optJSONObject("result") ?: return emptyList()
                result.optJSONArray("data")
            }
            root.has("data") -> root.optJSONArray("data")
            else -> null
        } ?: return emptyList()

        val list = mutableListOf<DragonItem>()
        for (i in 0 until dataArray.length()) {
            val obj = dataArray.getJSONObject(i)
            parseRow(obj)?.let { list.add(it) }
        }
        return list
    }

    /**
     * 兼容多种字段名（东方财富不同 report 字段不一致）
     */
    private fun parseRow(obj: JSONObject): DragonItem? {
        val name = obj.optString("SECURITY_NAME_ABBR", "").ifEmpty {
            obj.optString("SECURITY_NAME", "").ifEmpty { obj.optString("name", "") }
        }
        if (name.isBlank()) return null
        val code = obj.optString("SECURITY_CODE", "").ifEmpty {
            obj.optString("CODE", "").ifEmpty { obj.optString("code", "") }
        }
        if (code.isBlank()) return null

        val closePrice = obj.optDouble("CLOSE_PRICE", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("NEW_PRICE", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("close", 0.0)
        val changeRate = obj.optDouble("CHANGE_RATE", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("CHANGE_PERCENT", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("change_rate", 0.0)
        val netAmt = obj.optDouble("BILLBOARD_NET_AMT", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("NET_BUY_AMT", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("NET_AMT", 0.0).takeIf { it != 0.0 }
            ?: obj.optDouble("net_buy", 0.0)

        // 净买入：接口可能为元/万元/亿，按万转亿
        val netBuyYi = when {
            netAmt >= 1_0000_0000 -> netAmt / 1_0000_0000  // 已是亿
            netAmt >= 1_0000 -> netAmt / 10000.0           // 万元
            else -> netAmt
        }
        val secuCode = obj.optString("SECUCODE", "")
        val market = when {
            secuCode.uppercase().contains("SH") -> "sh"
            secuCode.uppercase().contains("SZ") -> "sz"
            code.startsWith("6") || code.startsWith("5") -> "sh"
            else -> "sz"
        }

        val tradeDate = obj.optString("TRADE_DATE", "").takeIf { it.isNotEmpty() }
        return DragonItem(
            name = name,
            code = code,
            closePrice = if (closePrice > 0) closePrice else 0.0,
            netBuy = netBuyYi,
            changePct = changeRate,
            isUp = changeRate >= 0,
            market = market,
            tradeDate = tradeDate
        )
    }
}
