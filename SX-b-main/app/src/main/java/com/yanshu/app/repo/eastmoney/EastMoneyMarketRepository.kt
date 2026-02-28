package com.yanshu.app.repo.eastmoney

import android.util.Log
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.yanshu.app.ui.hq.model.FundFlowInfo
import com.yanshu.app.ui.hq.model.MarketDistribution
import com.yanshu.app.ui.hq.model.SectorData
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * 东方财富第三方公开 API 行情仓库
 *
 * 提供以下数据（后端 API 不包含）：
 *  - 指数迷你走势折线点（trends2/get，同 EastMoneyDetailRepository.fetchTimeShare）
 *  - 行业/概念板块列表（clist/get）
 *  - 全市场涨跌平家数（ulist/get f104/f105/f106）
 *  - 港股通净流入资金（kamt/get）
 */
class EastMoneyMarketRepository(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(25, TimeUnit.SECONDS)
        .readTimeout(25, TimeUnit.SECONDS)
        .build(),
) {

    // ────────────── 指数走势折线 ──────────────

    /**
     * 获取指数迷你走势价格序列
     * @param secId 东方财富 secId，如 "1.000001"（上证）/ "0.399001"（深证）
     * @return 当日分时价格列表（最多 241 个点），空列表表示获取失败
     */
    suspend fun fetchIndexSparkline(secId: String): List<Float> = withContext(Dispatchers.IO) {
        val url = buildTrendUrl(secId)
        val root = parseRoot(executeGet(url)) ?: return@withContext emptyList()
        val trendArray = root.obj("data")?.arr("trends") ?: return@withContext emptyList()

        trendArray.mapNotNull { entry ->
            val values = entry.asString.split(",")
            values.getOrNull(1)?.toFloatOrNull()
        }
    }

    // ────────────── 板块列表 ──────────────

    /**
     * 获取行业或概念板块列表，按涨跌幅排序（取前 20 条）
     * @param sectorType 2=行业板块 3=概念板块
     */
    suspend fun fetchSectorList(sectorType: Int): List<SectorData> = withContext(Dispatchers.IO) {
        val raw = runCatching {
            if (PROXY_BASE_URL.isNotEmpty()) {
                executeGet("$PROXY_BASE_URL/sectors?type=$sectorType")
            } else {
                executeGet(buildSectorUrl(sectorType))
            }
        }.getOrElse { e ->
            Log.w(TAG, "fetchSectorList type=$sectorType failed: ${e.message}")
            return@withContext emptyList()
        }
        val root = parseRoot(raw) ?: run {
            Log.w(TAG, "fetchSectorList type=$sectorType parseRoot null, raw=${raw.take(200)}")
            return@withContext emptyList()
        }
        val diff = root.obj("data")?.arr("diff") ?: return@withContext emptyList()

        diff.mapNotNull { node ->
            val item = runCatching { node.asJsonObject }.getOrNull() ?: return@mapNotNull null
            val name = item.str("f14")
            val changePct = item.double("f3") ?: return@mapNotNull null
            val leadName = item.str("f128")
            val leadChange = item.double("f136") ?: 0.0
            if (name.isBlank()) return@mapNotNull null

            SectorData(
                name = name,
                changePercent = changePct,
                topStock = leadName,
                topStockChange = leadChange,
                isUp = changePct >= 0,
            )
        }
    }

    // ────────────── 涨跌平家数 ──────────────

    /**
     * 获取全市场涨/跌/平家数及11区间分布。
     * 通过分页拉取全部A股列表，自行统计每只股票的涨跌幅（f3）落入哪个区间。
     * @return Pair(Triple(上涨, 下跌, 平盘), MarketDistribution)，失败返回 null
     */
    suspend fun fetchRiseCount(): Pair<Triple<Int, Int, Int>, MarketDistribution>? = withContext(Dispatchers.IO) {
        val changePcts = runCatching { fetchAllChangePcts() }.getOrNull()
        if (changePcts.isNullOrEmpty()) return@withContext null
        computeDistribution(changePcts)
    }

    // ────────────── 港股通资金流向 ──────────────

    /**
     * 获取港股通北向 + 南向净买入资金
     * kamt API 字段单位为万元，转换为亿元显示
     */
    suspend fun fetchFundFlow(): List<FundFlowInfo> = withContext(Dispatchers.IO) {
        val root = parseRoot(executeGet(KAMT_URL)) ?: return@withContext emptyList()
        val data = root.obj("data") ?: return@withContext emptyList()

        // 北向资金：港股→A股（hk2sh 沪股通 + hk2sz 深股通），单位万元
        val northTotal = (data.obj("hk2sh")?.double("netBuyAmt") ?: 0.0) +
                         (data.obj("hk2sz")?.double("netBuyAmt") ?: 0.0)
        // 南向资金：A股→港股（sh2hk 港股通沪 + sz2hk 港股通深），单位万元
        val southTotal = (data.obj("sh2hk")?.double("netBuyAmt") ?: 0.0) +
                         (data.obj("sz2hk")?.double("netBuyAmt") ?: 0.0)

        listOf(
            FundFlowInfo(
                label = "北向资金净流入",
                value = formatAmountWan(northTotal),
                isPositive = northTotal >= 0,
            ),
            FundFlowInfo(
                label = "南向资金净流入",
                value = formatAmountWan(southTotal),
                isPositive = southTotal >= 0,
            ),
        )
    }

    // ────────────── 沪深两市合计涨跌平家数 ──────────────

    /**
     * 获取沪深两市合计涨/跌/平家数（用于首页涨平跌卡片）
     * @return Triple(涨家数, 跌家数, 平家数)，失败返回 null
     */
    suspend fun fetchCombinedRiseFall(): Triple<Int, Int, Int>? = withContext(Dispatchers.IO) {
        val changePcts = runCatching { fetchAllChangePcts() }.getOrNull()
        if (changePcts.isNullOrEmpty()) return@withContext null
        computeDistribution(changePcts).first
    }

    // ────────────── 全A股涨跌幅分页拉取 ──────────────

    /**
     * 分页拉取全部A股（沪深主板+中小板+创业板+科创板）的涨跌幅列表。
     * 第1页同时获取 data.total 确认总数，若总数超过单页容量则并发拉取剩余各页。
     * @return 每只股票的涨跌幅（f3）列表，失败返回空列表
     */
    private suspend fun fetchAllChangePcts(): List<Double> {
        // 第1页
        val page1Url = buildAllStocksUrl(page = 1)
        val page1Root = parseRoot(executeGet(page1Url)) ?: return emptyList()
        val dataObj = page1Root.obj("data") ?: return emptyList()
        val page1Diff = dataObj.arr("diff") ?: return emptyList()

        val page1Results = page1Diff.mapNotNull { node ->
            runCatching { node.asJsonObject }.getOrNull()?.double("f3")
        }

        val total = dataObj.int("total") ?: page1Results.size
        if (total <= ALL_STOCKS_PAGE_SIZE) return page1Results

        // 计算剩余页数并并发拉取
        val totalPages = (total + ALL_STOCKS_PAGE_SIZE - 1) / ALL_STOCKS_PAGE_SIZE
        val remainingResults = coroutineScope {
            (2..totalPages).map { page ->
                async(Dispatchers.IO) {
                    runCatching {
                        val url = buildAllStocksUrl(page)
                        val root = parseRoot(executeGet(url)) ?: return@runCatching emptyList<Double>()
                        val diff = root.obj("data")?.arr("diff") ?: return@runCatching emptyList()
                        diff.mapNotNull { node ->
                            runCatching { node.asJsonObject }.getOrNull()?.double("f3")
                        }
                    }.getOrDefault(emptyList())
                }
            }.map { it.await() }.flatten()
        }

        return page1Results + remainingResults
    }

    // ────────────── 分布计算 ──────────────

    /**
     * 根据涨跌幅列表自行计算11区间分布及涨跌平总家数。
     * 区间划分（以涨跌幅百分比 f3 为准）：
     *   涨停 ≥9.9 | >7% [7,9.9) | 5~7% [5,7) | 3~5% [3,5) | 0~3% (0,3)
     *   平 =0 | 0~3% (-3,0) | 3~5% [-5,-3] | 5~7% [-7,-5) | >7% (-9.9,-7] | 跌停 ≤-9.9
     */
    private fun computeDistribution(
        changePcts: List<Double>,
    ): Pair<Triple<Int, Int, Int>, MarketDistribution> {
        var riseStop = 0; var rise7 = 0; var rise5to7 = 0; var rise3to5 = 0; var rise0to3 = 0
        var flat = 0
        var fall0to3 = 0; var fall3to5 = 0; var fall5to7 = 0; var fall7 = 0; var fallStop = 0

        for (f3 in changePcts) {
            when {
                f3 >= 9.9   -> riseStop++
                f3 >= 7.0   -> rise7++
                f3 >= 5.0   -> rise5to7++
                f3 >= 3.0   -> rise3to5++
                f3 > 0.0    -> rise0to3++
                f3 == 0.0   -> flat++
                f3 > -3.0   -> fall0to3++
                f3 > -5.0   -> fall3to5++
                f3 > -7.0   -> fall5to7++
                f3 > -9.9   -> fall7++
                else        -> fallStop++
            }
        }

        val rise = riseStop + rise7 + rise5to7 + rise3to5 + rise0to3
        val fall = fall0to3 + fall3to5 + fall5to7 + fall7 + fallStop

        return Pair(
            Triple(rise, fall, flat),
            MarketDistribution(
                riseStop = riseStop,
                rise7    = rise7,
                rise5to7 = rise5to7,
                rise3to5 = rise3to5,
                rise0to3 = rise0to3,
                flat     = flat,
                fall0to3 = fall0to3,
                fall3to5 = fall3to5,
                fall5to7 = fall5to7,
                fall7    = fall7,
                fallStop = fallStop,
            ),
        )
    }

    // ────────────── A股主力净流入 ──────────────

    /**
     * 获取沪深两市合计主力净流入（超大单+大单），单位亿元
     * fflow API f62 字段单位为元
     */
    suspend fun fetchMainFundFlow(): FundFlowInfo? = withContext(Dispatchers.IO) {
        val url = "$ULIST_URL?fltt=2&invt=2&secids=1.000001,0.399001" +
            "&fields=f62,f184"
        runCatching {
            val root = parseRoot(executeGet(url)) ?: return@withContext null
            val diff = root.obj("data")?.arr("diff") ?: return@withContext null
            var totalYuan = 0.0
            diff.forEach { node ->
                val item = runCatching { node.asJsonObject }.getOrNull() ?: return@forEach
                totalYuan += item.double("f62") ?: 0.0
            }
            val yi = totalYuan / 1_0000_0000.0
            FundFlowInfo(
                label = "A股主力净流入",
                value = "${String.format("%.2f", yi)}亿",
                isPositive = totalYuan >= 0,
            )
        }.getOrNull()
    }

    // ────────────── 热门搜索股票 ──────────────

    /**
     * 获取热门搜索股票列表（东方财富热搜榜）
     * @param limit 返回数量，默认6条
     * @return 热搜股票列表，(rank, name, allcode) 格式，失败返回空列表
     */
    suspend fun fetchHotStocks(limit: Int = 6): List<HotStockItem> = withContext(Dispatchers.IO) {
        runCatching {
            val root = parseRoot(executeGet(HOT_RANK_URL)) ?: return@withContext emptyList()
            val arr = root.obj("data")?.arr("allHotRankStatVo") ?: return@withContext emptyList()
            arr.take(limit).mapIndexedNotNull { idx, node ->
                val item = runCatching { node.asJsonObject }.getOrNull() ?: return@mapIndexedNotNull null
                val code = item.str("code")
                val name = item.str("name")
                val market = item.int("market") ?: 0
                if (code.isBlank() || name.isBlank()) return@mapIndexedNotNull null
                val allcode = if (market == 1) "sh$code" else "sz$code"
                HotStockItem(rank = idx + 1, name = name, allcode = allcode)
            }
        }.getOrDefault(emptyList())
    }

    // ────────────── 批量行情（搜索结果价格） ──────────────

    /**
     * 批量获取股票行情（用于搜索结果填充价格）
     * @param allcodes allcode 列表，如 ["sh600036", "sz000001"]
     * @return secId → (price, changePct, change) 映射
     */
    suspend fun fetchBatchQuote(allcodes: List<String>): Map<String, StockQuoteSnapshot> =
        withContext(Dispatchers.IO) {
            if (allcodes.isEmpty()) return@withContext emptyMap()
            runCatching {
                val secIdPairs = allcodes.mapNotNull { allcode ->
                    allcodeToSecId(allcode)?.let { secId ->
                        secId to allcode.lowercase()
                    }
                }
                val secIds = secIdPairs.joinToString(",") { it.first }
                if (secIds.isEmpty()) return@withContext emptyMap()
                val allcodeBySecId = secIdPairs.toMap()
                val url = "$ULIST_URL?secids=$secIds&fields=f2,f3,f4,f12,f13,f14&fltt=2&invt=2"
                val root = parseRoot(executeGet(url)) ?: return@withContext emptyMap()
                val diff = root.obj("data")?.arr("diff") ?: return@withContext emptyMap()
                diff.mapNotNull { node ->
                    val item = runCatching { node.asJsonObject }.getOrNull() ?: return@mapNotNull null
                    val code = item.str("f12")
                    val mktId = item.str("f13")
                    if (code.isBlank()) return@mapNotNull null
                    val secId = "$mktId.$code"
                    val allcode = allcodeBySecId[secId] ?: when {
                        mktId == "1" -> "sh$code"
                        code.isBeiJingCode() -> "bj$code"
                        else -> "sz$code"
                    }
                    allcode to StockQuoteSnapshot(
                        price = item.double("f2") ?: 0.0,
                        changePct = item.double("f3") ?: 0.0,
                        change = item.double("f4") ?: 0.0,
                    )
                }.toMap()
            }.getOrDefault(emptyMap())
        }

    private fun allcodeToSecId(allcode: String): String? {
        val lower = allcode.lowercase()
        return when {
            lower.startsWith("sh") -> "1.${lower.removePrefix("sh")}"
            lower.startsWith("sz") -> "0.${lower.removePrefix("sz")}"
            lower.startsWith("bj") -> "0.${lower.removePrefix("bj")}"
            else -> null
        }
    }

    private fun String.isBeiJingCode(): Boolean {
        return startsWith("4")
            || startsWith("8")
            || startsWith("92")
            || startsWith("83")
            || startsWith("87")
            || startsWith("43")
    }

    // ────────────── URL 构建 ──────────────

    private fun buildTrendUrl(secId: String): String {
        return "$TREND_BASE_URL?secid=$secId" +
            "&fields1=f1,f2,f3,f4,f5,f6,f7,f8" +
            "&fields2=f51,f52,f53,f54,f55,f56,f57,f58" +
            "&ndays=1&iscr=0"
    }

    private fun buildSectorUrl(type: Int): String {
        return "$CLIST_URL?pn=1&pz=20&po=1&np=1&fltt=2&invt=2&fid=f3" +
            "&fs=m:90+t:$type" +
            "&fields=f3,f12,f14,f128,f136"
    }

    private fun buildAllStocksUrl(page: Int): String {
        return "$CLIST_URL?pn=$page&pz=$ALL_STOCKS_PAGE_SIZE&po=1&np=1&fltt=2&invt=2&fid=f3" +
            "&fs=m:0+t:6,m:0+t:13,m:0+t:80,m:1+t:2,m:0+t:81" +
            "&fields=f3,f12" +
            "&ut=fa5fd1943c7b386f172d6893dbfba10b"
    }

    // ────────────── 网络 / 解析工具 ──────────────

    @Throws(IOException::class)
    private fun executeGet(url: String): String {
        val proxyUrl = PROXY_BASE_URL
        val actualUrl = if (proxyUrl.isNotEmpty()) {
            "$proxyUrl/proxy?url=${java.net.URLEncoder.encode(url, "UTF-8")}"
        } else {
            url
        }
        val request = Request.Builder()
            .url(actualUrl)
            .header("User-Agent", USER_AGENT)
            .header("Referer", "https://quote.eastmoney.com/")
            .header("Accept", "*/*")
            .build()
        return client.newCall(request).execute().use { res ->
            if (!res.isSuccessful) throw IOException("EastMoney request failed: ${res.code}")
            res.body?.string().orEmpty()
        }
    }

    @Suppress("DEPRECATION")
    private fun parseRoot(content: String): JsonObject? {
        val json = JsonpParser.unwrap(content)
        val element = runCatching { JsonParser().parse(json) }.getOrNull() ?: return null
        if (!element.isJsonObject) return null
        return element.asJsonObject
    }

    private fun JsonObject.obj(key: String): JsonObject? {
        val node = get(key) ?: return null
        if (!node.isJsonObject) return null
        return node.asJsonObject
    }

    private fun JsonObject.arr(key: String) = runCatching {
        val node = get(key) ?: return@runCatching null
        if (!node.isJsonArray) return@runCatching null
        node.asJsonArray
    }.getOrNull()

    private fun JsonObject.str(key: String): String {
        val node = get(key) ?: return ""
        if (node.isJsonNull) return ""
        return runCatching { node.asString }.getOrDefault("")
    }

    private fun JsonObject.double(key: String): Double? {
        val node = get(key) ?: return null
        if (node.isJsonNull) return null
        return runCatching { node.asDouble }.getOrNull()
    }

    private fun JsonObject.int(key: String): Int? {
        val node = get(key) ?: return null
        if (node.isJsonNull) return null
        return runCatching { node.asInt }.getOrNull()
    }

    /** 单位：元 */
    private fun formatAmount(amount: Double): String {
        val abs = kotlin.math.abs(amount)
        val sign = if (amount < 0) "-" else ""
        return when {
            abs >= 1_0000_0000 -> "${sign}${String.format("%.2f", abs / 1_0000_0000.0)}亿"
            abs >= 10000 -> "${sign}${String.format("%.2f", abs / 10000.0)}万"
            else -> "${sign}${String.format("%.2f", abs)}"
        }
    }

    /** 单位：万元 → 亿元显示 */
    private fun formatAmountWan(amountWan: Double): String {
        val sign = if (amountWan < 0) "-" else ""
        val yi = kotlin.math.abs(amountWan) / 10000.0
        return "${sign}${String.format("%.2f", yi)}亿"
    }

    companion object {
        private const val TAG = "EastMoneyMarket"
        private const val TREND_BASE_URL = "https://push2his.eastmoney.com/api/qt/stock/trends2/get"
        private const val CLIST_URL = "https://push2.eastmoney.com/api/qt/clist/get"
        private const val ULIST_URL = "https://push2.eastmoney.com/api/qt/ulist/get"
        private const val ALL_STOCKS_PAGE_SIZE = 5000
        private const val KAMT_URL = "https://push2.eastmoney.com/api/qt/kamt/get" +
            "?fields1=f1,f2,f3,f4&fields2=f51,f52,f53,f54,f56,f62,f63,f65,f66"
        private const val HOT_RANK_URL = "https://emappdata.eastmoney.com/stockrank/getAllCurrentList"
        private const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36"

        /**
         * Playwright proxy server base URL.
         * Set to empty string to call EastMoney APIs directly.
         * Emulator / proxy usage can be configured in debug builds only.
         */
        var PROXY_BASE_URL = ""
    }
}

data class HotStockItem(
    val rank: Int,
    val name: String,
    val allcode: String,
)

data class StockQuoteSnapshot(
    val price: Double,
    val changePct: Double,
    val change: Double,
)
