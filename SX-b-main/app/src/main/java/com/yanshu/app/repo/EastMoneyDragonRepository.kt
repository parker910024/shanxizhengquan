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
 * 东方财富 龙虎榜 数据（直连 datacenter-web.eastmoney.com）
 * 接口：RPT_DAILYBILLBOARD_DETAILS 每日龙虎榜个股列表
 */
object EastMoneyDragonRepository {

    private const val TAG = "EastMoneyDragon"
    private const val BASE_URL = "https://datacenter-web.eastmoney.com/api/data/v1/get"

    private const val MAIN_REPORT = "RPT_DAILYBILLBOARD_DETAILS"

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    // ────────────── 内存缓存 ──────────────
    private val cache = LinkedHashMap<String, CacheEntry>(8, 0.75f, true)
    private const val CACHE_MAX_SIZE = 10
    private const val CACHE_EXPIRE_MS = 5 * 60 * 1000L  // 5分钟过期

    private data class CacheEntry(
        val data: List<DragonItem>,
        val timestamp: Long = System.currentTimeMillis()
    ) {
        fun isExpired(): Boolean = System.currentTimeMillis() - timestamp > CACHE_EXPIRE_MS
    }

    private data class ParsedPage(
        val items: List<DragonItem>,
        val pages: Int = 1
    )

    /**
     * 按日期获取龙虎榜列表（东方财富数据中心）
     * 优化：直接使用已验证有效的 RPT_DAILYBILLBOARD_DETAILS + TRADE_DATE<='日期'
     * @param date 格式 yyyy-MM-dd
     */
    suspend fun getListByDate(date: String): Result<List<DragonItem>> = withContext(Dispatchers.IO) {
        // 1. 检查缓存
        cache[date]?.let { entry ->
            if (!entry.isExpired()) {
                Log.d(TAG, "cache hit for $date, items=${entry.data.size}")
                return@withContext Result.success(entry.data)
            } else {
                cache.remove(date)
            }
        }

        // 2. 请求东方财富接口
        val result = fetchDragonList(date)

        result.fold(
            onSuccess = { list ->
                // 写入缓存
                if (cache.size >= CACHE_MAX_SIZE) {
                    cache.keys.firstOrNull()?.let { cache.remove(it) }
                }
                cache[date] = CacheEntry(list)

                Result.success(list)
            },
            onFailure = { Result.failure(it) }
        )
    }

    /** 与 iOS 完全一致的 columns，保证拿到的字段一致 */
    private val columns = listOf(
        "SECURITY_CODE", "SECUCODE", "SECURITY_NAME_ABBR", "TRADE_DATE", "EXPLAIN",
        "CLOSE_PRICE", "CHANGE_RATE", "BILLBOARD_NET_AMT", "BILLBOARD_BUY_AMT",
        "BILLBOARD_SELL_AMT", "BILLBOARD_DEAL_AMT", "ACCUM_AMOUNT", "DEAL_NET_RATIO",
        "DEAL_AMOUNT_RATIO", "TURNOVERRATE", "FREE_MARKET_CAP", "EXPLANATION",
        "D1_CLOSE_ADJCHRATE", "D2_CLOSE_ADJCHRATE", "D5_CLOSE_ADJCHRATE",
        "D10_CLOSE_ADJCHRATE", "SECURITY_TYPE_CODE"
    ).joinToString(",")

    /** 请求龙虎榜数据：仅查询所选日期，当天无数据则返回空列表 */
    private fun fetchDragonList(date: String): Result<List<DragonItem>> {
        val exactFilter = "(TRADE_DATE='$date')"
        val exactResult = fetchWithFilter(reportName = MAIN_REPORT, filter = exactFilter)
        if (exactResult.isSuccess) {
            val exactList = exactResult.getOrNull() ?: emptyList()
            if (exactList.isNotEmpty()) {
                Log.d(TAG, "dragon exact hit: date=$date count=${exactList.size}")
                return Result.success(exactList)
            }
        }
        Log.d(TAG, "dragon no data for date=$date")
        return Result.success(emptyList())
    }

    private fun fetchWithFilter(reportName: String, filter: String): Result<List<DragonItem>> = runCatching {
        val pageSize = 500
        val allItems = mutableListOf<DragonItem>()

        val firstPage = requestPage(reportName, filter, pageNumber = 1, pageSize = pageSize)
        allItems.addAll(firstPage.items)

        if (firstPage.pages > 1) {
            for (page in 2..firstPage.pages) {
                val nextPage = requestPage(reportName, filter, pageNumber = page, pageSize = pageSize)
                allItems.addAll(nextPage.items)
            }
        }
        allItems
    }.onFailure { e -> Log.w(TAG, "fetch reportName=$reportName filter=$filter", e) }

    private fun requestPage(
        reportName: String,
        filter: String,
        pageNumber: Int,
        pageSize: Int
    ): ParsedPage {
        return requestPage(
            reportName = reportName,
            filter = filter,
            pageNumber = pageNumber,
            pageSize = pageSize,
            pageColumns = columns,
            sortColumns = "SECURITY_CODE,TRADE_DATE",
            sortTypes = "1,-1"
        )
    }

    private fun requestPage(
        reportName: String,
        filter: String,
        pageNumber: Int,
        pageSize: Int,
        pageColumns: String,
        sortColumns: String,
        sortTypes: String
    ): ParsedPage {
        val url = "$BASE_URL?" +
            "sortColumns=$sortColumns" +
            "&sortTypes=$sortTypes" +
            "&pageSize=$pageSize" +
            "&pageNumber=$pageNumber" +
            "&reportName=$reportName" +
            "&columns=${URLEncoder.encode(pageColumns, "UTF-8")}" +
            "&source=WEB" +
            "&client=WEB" +
            "&filter=${URLEncoder.encode(filter, "UTF-8")}"

        val request = Request.Builder()
            .url(url)
            .header("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15")
            .header("Referer", "https://data.eastmoney.com/")
            .header("Accept", "application/json, text/plain, */*")
            .get()
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) throw Exception("HTTP ${response.code}")
        val body = response.body?.string() ?: throw Exception("empty body")
        return parseResponse(body)
    }

    /**
     * 解析东方财富 datacenter API 返回
     * 常见结构: { "success": true, "result": { "data": [...], "total": n } } 或 { "data": [...] }
     * 无数据或 reportName 错误时可能返回 result: null，需安全解析
     */
    private fun parseResponse(json: String): ParsedPage {
        val root = runCatching { JSONObject(json) }.getOrNull() ?: return ParsedPage(emptyList(), 1)
        val pages = root.optJSONObject("result")?.optInt("pages", 1)?.takeIf { it > 0 } ?: 1
        val dataArray = when {
            root.has("result") -> {
                val result = root.optJSONObject("result") ?: return ParsedPage(emptyList(), pages)
                result.optJSONArray("data")
            }
            root.has("data") -> root.optJSONArray("data")
            else -> null
        } ?: return ParsedPage(emptyList(), pages)

        val list = mutableListOf<DragonItem>()
        for (i in 0 until dataArray.length()) {
            val obj = dataArray.getJSONObject(i)
            parseRow(obj)?.let { list.add(it) }
        }
        return ParsedPage(list, pages)
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

        val closePrice = firstNumber(obj, "CLOSE_PRICE", "NEW_PRICE", "close") ?: 0.0
        val changeRate = firstNumber(obj, "CHANGE_RATE", "CHANGE_PERCENT", "change_rate") ?: 0.0
        val netAmt = firstNumber(obj, "BILLBOARD_NET_AMT", "NET_BUY_AMT", "NET_AMT", "net_buy")
            ?: 0.0
        val secuCode = obj.optString("SECUCODE", "")
        val market = when {
            secuCode.uppercase().contains("SH") -> "sh"
            secuCode.uppercase().contains("SZ") -> "sz"
            secuCode.uppercase().contains("BJ") -> "bj"
            code.startsWith("8") || code.startsWith("4") -> "bj"
            code.startsWith("6") || code.startsWith("5") -> "sh"
            else -> "sz"
        }

        val tradeDate = obj.optString("TRADE_DATE", "").takeIf { it.isNotEmpty() }
        return DragonItem(
            name = name,
            code = code,
            closePrice = if (closePrice > 0) closePrice else 0.0,
            netBuy = netAmt,
            changePct = changeRate,
            isUp = changeRate >= 0,
            market = market,
            tradeDate = tradeDate
        )
    }

    private fun firstNumber(obj: JSONObject, vararg keys: String): Double? {
        for (key in keys) {
            val value = obj.opt(key)
            when (value) {
                is Number -> return value.toDouble()
                is String -> {
                    val text = value.trim().replace(",", "")
                    if (text.isEmpty() || text == "--") continue
                    text.toDoubleOrNull()?.let { return it }
                }
            }
        }
        return null
    }
}
