package com.yanshu.app.repo.sina

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.yanshu.app.repo.eastmoney.EastMoneyDetailRepository
import com.yanshu.app.ui.hq.detail.model.DetailNewsItem
import com.yanshu.app.ui.hq.detail.model.KLinePoint
import com.yanshu.app.ui.hq.detail.model.OrderBookData
import com.yanshu.app.ui.hq.detail.model.OrderBookLevel
import com.yanshu.app.ui.hq.detail.model.ResolvedDetailTarget
import com.yanshu.app.ui.hq.detail.model.SnapshotData
import com.yanshu.app.ui.hq.detail.model.TimeSharePoint
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import java.io.IOException
import java.nio.charset.Charset
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * 新浪财经数据源 —— 替代东方财富 push2 API（无反爬问题）。
 *
 * 接口说明：
 *  - 实时行情 + 五档盘口：hq.sinajs.cn
 *  - K线/分时：money.finance.sina.com.cn  CN_MarketData.getKLineData
 *  - 新闻：沿用东方财富股吧（新闻接口无反爬）
 */
class SinaStockRepository(
    private val client: OkHttpClient = buildClient(),
    private val gson: Gson = Gson(),
) {

    // ===================== 实时快照 =====================

    /**
     * 获取股票实时行情快照（今开/最高/最低/昨收/最新价/成交量/成交额）。
     * 数据源：新浪 hq.sinajs.cn
     */
    suspend fun fetchSnapshot(target: ResolvedDetailTarget): SnapshotData? =
        withContext(Dispatchers.IO) {
            val quoteCode = target.quoteCode // e.g. "sh600519"
            val url = buildQuoteUrl(quoteCode)
            Log.d(TAG, "fetchSnapshot url=$url")
            val raw = runCatching { executeGetSafe(url, retries = 2, gbk = true) }.getOrElse { e ->
                Log.e(TAG, "fetchSnapshot error: ${e.message}", e)
                return@withContext null
            }
            Log.d(TAG, "fetchSnapshot raw=${raw.take(300)}")
            parseSinaQuoteToSnapshot(raw, target)
        }

    // ===================== 五档盘口 =====================

    /**
     * 获取五档买卖盘数据。新浪行情字符串已包含买卖各5档。
     * @param secId 东方财富格式 "1.600519"，内部转为新浪格式 "sh600519"
     */
    suspend fun fetchOrderBook(secId: String): OrderBookData =
        withContext(Dispatchers.IO) {
            val quoteCode = secIdToSinaCode(secId)
            val url = buildQuoteUrl(quoteCode)
            Log.d(TAG, "fetchOrderBook url=$url")
            val raw = runCatching { executeGetSafe(url, retries = 2, gbk = true) }.getOrElse {
                Log.e(TAG, "fetchOrderBook error: ${it.message}", it)
                return@withContext OrderBookData()
            }
            parseSinaQuoteToOrderBook(raw)
        }

    // ===================== 分时 =====================

    /**
     * 获取当日分时数据（1分钟K线转换）。
     */
    suspend fun fetchTimeShare(target: ResolvedDetailTarget): List<TimeSharePoint> =
        withContext(Dispatchers.IO) {
            val symbol = target.quoteCode
            // 优先尝试主接口，失败则尝试备用接口
            val urls = listOf(
                buildKLineUrl(symbol, scale = 1, datalen = 242),
                buildKLineUrlAlt(symbol, scale = 1, datalen = 242),
            )
            for (url in urls) {
                Log.d(TAG, "fetchTimeShare url=$url")
                val raw: String
                try {
                    raw = executeGetSafe(url, retries = 2)
                } catch (e: IOException) {
                    Log.e(TAG, "fetchTimeShare error: ${e.message}", e)
                    continue
                }
                Log.d(TAG, "fetchTimeShare raw(${raw.length})=${raw.take(500)}")
                val points = parseKLineJson(raw)
                if (points.isNotEmpty()) {
                    val result = convertToTimeShare(points)
                    Log.d(TAG, "fetchTimeShare parsed ${result.size} points")
                    return@withContext result
                }
            }
            Log.w(TAG, "fetchTimeShare Sina failed for $symbol, falling back to EastMoney")
            val fallback = runCatching { eastMoneyNewsRepo.fetchTimeShare(target) }.getOrNull()
            if (!fallback.isNullOrEmpty()) {
                Log.d(TAG, "fetchTimeShare EastMoney fallback: ${fallback.size} points")
                return@withContext fallback
            }
            Log.w(TAG, "fetchTimeShare all sources failed for $symbol")
            emptyList()
        }

    // ===================== K线 =====================

    /**
     * 获取K线数据。
     * @param klt 周期类型（兼容东方财富定义）：5=五分钟, 15=15分钟, 30=30分钟, 60=60分钟,
     *            101=日K, 102=周K, 103=月K
     */
    suspend fun fetchKLine(
        target: ResolvedDetailTarget,
        klt: Int,
        limit: Int = 120,
    ): List<KLinePoint> = withContext(Dispatchers.IO) {
        val symbol = target.quoteCode
        when (klt) {
            102 -> fetchAggregatedKLine(symbol, limit, aggregateWeekly = true)
            103 -> fetchAggregatedKLine(symbol, limit, aggregateWeekly = false)
            else -> {
                val scale = kltToSinaScale(klt)
                val urls = listOf(
                    buildKLineUrl(symbol, scale, limit),
                    buildKLineUrlAlt(symbol, scale, limit),
                )
                for (url in urls) {
                    Log.d(TAG, "fetchKLine klt=$klt scale=$scale url=$url")
                    val raw: String
                    try {
                        raw = executeGetSafe(url, retries = 2)
                    } catch (e: IOException) {
                        Log.e(TAG, "fetchKLine error: ${e.message}", e)
                        continue
                    }
                    Log.d(TAG, "fetchKLine raw(${raw.length})=${raw.take(500)}")
                    val points = parseKLineJson(raw)
                    if (points.isNotEmpty()) {
                        Log.d(TAG, "fetchKLine parsed ${points.size} points")
                        return@withContext points
                    }
                }
                Log.w(TAG, "fetchKLine all urls failed for $symbol klt=$klt")
                emptyList()
            }
        }
    }

    // ===================== 新闻（沿用东方财富） =====================

    private val eastMoneyNewsRepo by lazy { EastMoneyDetailRepository() }

    suspend fun fetchArticleNews(
        target: ResolvedDetailTarget,
        pageSize: Int = 20,
    ): List<DetailNewsItem> {
        return eastMoneyNewsRepo.fetchArticleNews(target, pageSize)
    }

    suspend fun fetchFastNews(pageSize: Int = 20): List<DetailNewsItem> {
        return eastMoneyNewsRepo.fetchFastNews(pageSize)
    }

    // ═══════════════════════════════════════════════════
    //  内部：解析新浪行情字符串
    // ═══════════════════════════════════════════════════

    /**
     * 新浪 hq.sinajs.cn 返回格式：
     * ```
     * var hq_str_sh600519="贵州茅台,今开,昨收,当前价,最高,最低,买1价,卖1价,成交量(股),成交额(元),
     *   买1量,买1价,买2量,买2价,买3量,买3价,买4量,买4价,买5量,买5价,
     *   卖1量,卖1价,卖2量,卖2价,卖3量,卖3价,卖4量,卖4价,卖5量,卖5价,
     *   日期,时间,00";
     * ```
     *
     * 字段索引（逗号分隔，第0个是名称）：
     *  0=名称  1=今开  2=昨收  3=当前价  4=最高  5=最低
     *  6=买一价(竞买价)  7=卖一价(竞卖价)  8=成交量(股)  9=成交额(元)
     *  10=买一量  11=买一价  12=买二量  13=买二价  14=买三量  15=买三价
     *  16=买四量  17=买四价  18=买五量  19=买五价
     *  20=卖一量  21=卖一价  22=卖二量  23=卖二价  24=卖三量  25=卖三价
     *  26=卖四量  27=卖四价  28=卖五量  29=卖五价
     *  30=日期  31=时间
     */
    private fun parseSinaFields(raw: String): List<String>? {
        val start = raw.indexOf('"')
        val end = raw.lastIndexOf('"')
        if (start < 0 || end <= start) return null
        val content = raw.substring(start + 1, end)
        if (content.isBlank()) return null
        return content.split(",")
    }

    private fun parseSinaQuoteToSnapshot(
        raw: String,
        target: ResolvedDetailTarget,
    ): SnapshotData? {
        val fields = parseSinaFields(raw) ?: return null
        if (fields.size < 32) return null

        val name = fields[0]
        val open = fields[1].toDoubleOrNull()
        val preClose = fields[2].toDoubleOrNull()
        val price = fields[3].toDoubleOrNull()
        val high = fields[4].toDoubleOrNull()
        val low = fields[5].toDoubleOrNull()
        val volume = fields[8].toDoubleOrNull()   // 股
        val amount = fields[9].toDoubleOrNull()    // 元

        val change = if (price != null && preClose != null) price - preClose else null
        val changePct = if (price != null && preClose != null && preClose != 0.0)
            (price - preClose) / preClose * 100.0 else null

        val limitUp = calculateLimitUp(target.code, preClose)
        val limitDown = calculateLimitDown(target.code, preClose)

        return SnapshotData(
            code = target.code,
            name = name,
            price = price,
            change = change,
            changePct = changePct,
            open = open,
            preClose = preClose,
            high = high,
            low = low,
            volume = volume,
            amount = amount,
            limitUp = limitUp,
            limitDown = limitDown,
            turnover = null,           // 新浪基础行情不含换手率
            marketValue = null,        // 新浪基础行情不含总市值
            circulationMarketValue = null,
        )
    }

    private fun parseSinaQuoteToOrderBook(raw: String): OrderBookData {
        val fields = parseSinaFields(raw) ?: return OrderBookData()
        if (fields.size < 30) return OrderBookData()

        // 买五档: 量在偶数索引, 价在奇数索引（从10开始）
        val bids = listOf(
            OrderBookLevel(
                price = fields[11].toDoubleOrNull() ?: 0.0,
                volume = fields[10].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[13].toDoubleOrNull() ?: 0.0,
                volume = fields[12].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[15].toDoubleOrNull() ?: 0.0,
                volume = fields[14].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[17].toDoubleOrNull() ?: 0.0,
                volume = fields[16].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[19].toDoubleOrNull() ?: 0.0,
                volume = fields[18].toDoubleOrNull()?.toInt() ?: 0,
            ),
        )

        // 卖五档
        val asks = listOf(
            OrderBookLevel(
                price = fields[21].toDoubleOrNull() ?: 0.0,
                volume = fields[20].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[23].toDoubleOrNull() ?: 0.0,
                volume = fields[22].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[25].toDoubleOrNull() ?: 0.0,
                volume = fields[24].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[27].toDoubleOrNull() ?: 0.0,
                volume = fields[26].toDoubleOrNull()?.toInt() ?: 0,
            ),
            OrderBookLevel(
                price = fields[29].toDoubleOrNull() ?: 0.0,
                volume = fields[28].toDoubleOrNull()?.toInt() ?: 0,
            ),
        )

        Log.d(TAG, "orderBook bids=${bids.map { "${it.price}x${it.volume}" }}")
        Log.d(TAG, "orderBook asks=${asks.map { "${it.price}x${it.volume}" }}")

        return OrderBookData(asks = asks, bids = bids)
    }

    // ═══════════════════════════════════════════════════
    //  内部：解析 K线
    // ═══════════════════════════════════════════════════

    /**
     * Sina K线 JSON 返回格式：
     * ```json
     * [
     *   {"day":"2026-02-25","open":"1810.000","high":"1825.000",
     *    "low":"1805.000","close":"1820.000","volume":"4546171800"},
     *   ...
     * ]
     * ```
     * 分钟级别时 day 含时间："2026-02-25 14:55:00"
     */
    private data class SinaKLineItem(
        val day: String = "",
        val open: String = "",
        val high: String = "",
        val low: String = "",
        val close: String = "",
        val volume: String = "",
    )

    /**
     * 统一解析 K线 JSON —— 兼容多种新浪返回格式：
     * 1. 标准 JSON 数组  `[{"day":"...","open":"...","close":"...","high":"...","low":"...","volume":"..."}]`
     * 2. 非标准 JS 对象   `[{day:"...",open:"...",...}]`  （key 未加引号）
     * 3. JSONP 包裹       `var ...=[{...}];`
     */
    private fun parseKLineJson(raw: String): List<KLinePoint> {
        if (raw.isBlank()) {
            Log.w(TAG, "parseKLineJson: empty input")
            return emptyList()
        }

        // 步骤1：去除 JSONP 包裹 —— "var xxx=...;" → 取 = 后面的内容
        var json = raw.trim()
        val eqIdx = json.indexOf('=')
        if (eqIdx >= 0 && !json.startsWith("[") && !json.startsWith("{")) {
            json = json.substring(eqIdx + 1).trim().removeSuffix(";").trim()
        }

        // 步骤2：如果 key 没有加引号，手动补上（JS 对象 → 标准 JSON）
        if (json.contains(Regex("""\{[a-zA-Z]"""))) {
            json = json.replace(Regex("""(\{|,)\s*([a-zA-Z_]\w*)\s*:"""), """$1"$2":""")
        }

        // 步骤3：尝试 Gson 解析
        val type = object : TypeToken<List<SinaKLineItem>>() {}.type
        val items: List<SinaKLineItem>? = runCatching {
            gson.fromJson<List<SinaKLineItem>>(json, type)
        }.getOrElse { e ->
            Log.e(TAG, "parseKLineJson Gson failed: ${e.message}, json prefix=${json.take(200)}")
            null
        }

        if (items == null || items.isEmpty()) {
            Log.w(TAG, "parseKLineJson: 0 items parsed, raw prefix=${raw.take(300)}")
            return emptyList()
        }

        return items.mapNotNull { item ->
            val open = item.open.toDoubleOrNull() ?: return@mapNotNull null
            val close = item.close.toDoubleOrNull() ?: return@mapNotNull null
            val high = item.high.toDoubleOrNull() ?: return@mapNotNull null
            val low = item.low.toDoubleOrNull() ?: return@mapNotNull null
            val volume = item.volume.toDoubleOrNull() ?: 0.0
            val amount = (open + close) / 2.0 * volume

            KLinePoint(
                time = item.day,
                open = open,
                close = close,
                high = high,
                low = low,
                volume = volume,
                amount = amount,
            )
        }
    }

    /**
     * 将 KLinePoint 列表转为分时数据，计算 VWAP 均线。
     */
    private fun convertToTimeShare(points: List<KLinePoint>): List<TimeSharePoint> {
        var cumulativeAmount = 0.0
        var cumulativeVolume = 0.0

        return points.map { pt ->
            val amount = pt.close * pt.volume
            cumulativeAmount += amount
            cumulativeVolume += pt.volume
            val avgPrice =
                if (cumulativeVolume > 0) cumulativeAmount / cumulativeVolume else pt.close

            TimeSharePoint(
                time = pt.time,
                price = pt.close,
                avgPrice = avgPrice,
                volume = pt.volume,
            )
        }
    }

    // ═══════════════════════════════════════════════════
    //  内部：周K / 月K 聚合
    // ═══════════════════════════════════════════════════

    /**
     * 新浪不直接提供周K/月K，用日K数据聚合。
     */
    private suspend fun fetchAggregatedKLine(
        symbol: String,
        limit: Int,
        aggregateWeekly: Boolean,
    ): List<KLinePoint> {
        val tag = if (aggregateWeekly) "weekK" else "monthK"
        val dailyLimit = if (aggregateWeekly) limit * 5 + 20 else limit * 22 + 60
        val urls = listOf(
            buildKLineUrl(symbol, scale = 240, datalen = dailyLimit.coerceAtMost(1000)),
            buildKLineUrlAlt(symbol, scale = 240, datalen = dailyLimit.coerceAtMost(1000)),
        )
        for (url in urls) {
            Log.d(TAG, "fetchAggregatedKLine($tag) url=$url")
            val raw: String
            try {
                raw = executeGetSafe(url, retries = 2)
            } catch (e: IOException) {
                Log.e(TAG, "fetchAggregatedKLine($tag) error: ${e.message}")
                continue
            }
            Log.d(TAG, "fetchAggregatedKLine($tag) raw(${raw.length})=${raw.take(300)}")
            val dailyPoints = parseKLineJson(raw)
            if (dailyPoints.isNotEmpty()) {
                return if (aggregateWeekly) aggregateToWeekly(dailyPoints, limit)
                else aggregateToMonthly(dailyPoints, limit)
            }
        }
        Log.w(TAG, "fetchAggregatedKLine($tag) all urls failed for $symbol")
        return emptyList()
    }

    private fun aggregateToWeekly(dailyPoints: List<KLinePoint>, limit: Int): List<KLinePoint> {
        val cal = Calendar.getInstance()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.CHINA)

        val grouped = dailyPoints.groupBy { point ->
            val date = runCatching { dateFormat.parse(point.time.take(10)) }.getOrNull()
                ?: return@groupBy ""
            cal.time = date
            "${cal.get(Calendar.YEAR)}-W${String.format("%02d", cal.get(Calendar.WEEK_OF_YEAR))}"
        }.filter { it.key.isNotBlank() }

        return grouped.values.map { points ->
            KLinePoint(
                time = points.first().time,
                open = points.first().open,
                close = points.last().close,
                high = points.maxOf { it.high },
                low = points.minOf { it.low },
                volume = points.sumOf { it.volume },
                amount = points.sumOf { it.amount },
            )
        }.takeLast(limit)
    }

    private fun aggregateToMonthly(dailyPoints: List<KLinePoint>, limit: Int): List<KLinePoint> {
        val grouped = dailyPoints.groupBy { point ->
            point.time.take(7) // "yyyy-MM"
        }

        return grouped.values.map { points ->
            KLinePoint(
                time = points.first().time,
                open = points.first().open,
                close = points.last().close,
                high = points.maxOf { it.high },
                low = points.minOf { it.low },
                volume = points.sumOf { it.volume },
                amount = points.sumOf { it.amount },
            )
        }.takeLast(limit)
    }

    // ═══════════════════════════════════════════════════
    //  工具方法
    // ═══════════════════════════════════════════════════

    /** 东方财富 secId "1.600519" → 新浪格式 "sh600519" */
    private fun secIdToSinaCode(secId: String): String {
        val parts = secId.split(".")
        if (parts.size != 2) return secId
        val code = parts[1]
        val prefix = when {
            parts[0] == "1" -> "sh"
            code.startsWith("4") || code.startsWith("8") -> "bj"
            else -> "sz"
        }
        return "$prefix$code"
    }

    /** 东方财富 klt → 新浪 scale */
    private fun kltToSinaScale(klt: Int): Int = when (klt) {
        1 -> 1
        5 -> 5
        15 -> 15
        30 -> 30
        60 -> 60
        101 -> 240   // 日K：1天=240分钟
        else -> 240
    }

    /** 根据昨收价计算涨停价 */
    private fun calculateLimitUp(code: String, preClose: Double?): Double? {
        if (preClose == null || preClose <= 0) return null
        val pct = getLimitPct(code)
        return Math.round(preClose * (1 + pct) * 100.0) / 100.0
    }

    /** 根据昨收价计算跌停价 */
    private fun calculateLimitDown(code: String, preClose: Double?): Double? {
        if (preClose == null || preClose <= 0) return null
        val pct = getLimitPct(code)
        return Math.round(preClose * (1 - pct) * 100.0) / 100.0
    }

    /** 涨跌停比例：科创板/创业板 20%, 北交所 30%, 主板 10% */
    private fun getLimitPct(code: String): Double = when {
        code.startsWith("688") || code.startsWith("300") -> 0.20
        code.startsWith("4") || code.startsWith("8") -> 0.30
        else -> 0.10
    }

    // ═══════════════════════════════════════════════════
    //  URL 构建
    // ═══════════════════════════════════════════════════

    private fun buildQuoteUrl(quoteCode: String): String {
        val rn = System.currentTimeMillis()
        return "$QUOTE_URL/rn=$rn&list=$quoteCode"
    }

    private fun buildKLineUrl(symbol: String, scale: Int, datalen: Int): String {
        return "$KLINE_URL?symbol=$symbol&scale=$scale&ma=no&datalen=$datalen"
    }

    /** 备用K线接口（vip.stock 域名） */
    private fun buildKLineUrlAlt(symbol: String, scale: Int, datalen: Int): String {
        return "$KLINE_URL_ALT?symbol=$symbol&scale=$scale&ma=no&datalen=$datalen"
    }

    // ═══════════════════════════════════════════════════
    //  网络请求
    // ═══════════════════════════════════════════════════

    /**
     * 执行 GET 请求。
     * @param gbk 是否以 GBK 编码读取响应（新浪行情接口使用 GBK）
     */
    @Throws(IOException::class)
    private fun executeGet(url: String, gbk: Boolean = false): String {
        val request = Request.Builder()
            .url(url)
            .header("User-Agent", USER_AGENT)
            .header("Referer", REFERER)
            .header("Accept", "*/*")
            .header("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
            .build()

        val response = client.newCall(request).execute()
        response.use { res ->
            if (!res.isSuccessful) {
                Log.e(TAG, "executeGet failed code=${res.code} url=$url")
                throw IOException("Sina request failed: ${res.code}")
            }
            val body = if (gbk) {
                // hq.sinajs.cn 使用 GBK 编码
                val bytes = res.body?.bytes() ?: return ""
                String(bytes, GBK_CHARSET)
            } else {
                res.body?.string().orEmpty()
            }
            if (body.isEmpty()) {
                Log.w(TAG, "executeGet empty body url=$url")
            }
            return body
        }
    }

    /**
     * 带重试的 GET 请求（指数退避 + 随机抖动）。
     */
    private suspend fun executeGetSafe(
        url: String,
        retries: Int = 1,
        gbk: Boolean = false,
    ): String {
        var lastError: IOException? = null
        repeat(retries + 1) { attempt ->
            try {
                return executeGet(url, gbk)
            } catch (e: IOException) {
                lastError = e
                Log.w(
                    TAG,
                    "executeGetSafe attempt ${attempt + 1}/${retries + 1} failed: ${e.message}",
                )
                if (attempt < retries) {
                    val baseDelay = 200L * (1 shl attempt) // 200, 400, 800 …
                    val jitter = (Math.random() * 100).toLong()
                    delay(baseDelay + jitter)
                }
            }
        }
        throw lastError ?: IOException("Sina request failed after ${retries + 1} attempts")
    }

    companion object {
        private const val TAG = "zs_ts"

        /** 新浪实时行情接口（包含五档盘口） */
        private const val QUOTE_URL = "https://hq.sinajs.cn"

        /** 新浪K线 / 分时接口（主） */
        private const val KLINE_URL =
            "https://money.finance.sina.com.cn/quotes_service/api/json_v2.php/CN_MarketData.getKLineData"

        /** 新浪K线 / 分时接口（备用） */
        private const val KLINE_URL_ALT =
            "https://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/CN_MarketData.getKLineData"

        private const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 " +
                "(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36"
        private const val REFERER = "https://finance.sina.com.cn"

        private val GBK_CHARSET: Charset = Charset.forName("GBK")

        private fun buildClient(): OkHttpClient {
            return OkHttpClient.Builder()
                .retryOnConnectionFailure(true)
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .writeTimeout(10, TimeUnit.SECONDS)
                .callTimeout(15, TimeUnit.SECONDS)
                .protocols(listOf(Protocol.HTTP_1_1))
                .build()
        }
    }
}
