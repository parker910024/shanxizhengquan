package com.yanshu.app.repo.eastmoney

import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonParser
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
import okhttp3.ConnectionPool
import okhttp3.Dns
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import java.io.IOException
import java.net.Inet4Address
import java.net.InetAddress
import java.util.concurrent.TimeUnit

class EastMoneyDetailRepository(
    private val client: OkHttpClient = buildClient(),
    @Suppress("unused")
    private val gson: Gson = Gson(),
) {

    suspend fun fetchSnapshot(target: ResolvedDetailTarget): SnapshotData? = withContext(Dispatchers.IO) {
        val url = buildSnapshotUrl(target.secId)
        Log.d(TAG, "fetchSnapshot url=$url")
        val raw = runCatching { executeGetSafe(url, retries = 3) }.getOrElse { e ->
            Log.e(TAG, "fetchSnapshot error: ${e.message}", e)
            return@withContext null
        }
        Log.d(TAG, "fetchSnapshot raw=${raw.take(300)}")
        val root = parseRootObject(raw) ?: return@withContext null
        val data = root.obj("data") ?: return@withContext null

        SnapshotData(
            code = data.str("f57").ifBlank { target.code },
            name = data.str("f58"),
            price = data.double("f43"),
            change = data.double("f169"),
            changePct = data.double("f170"),
            open = data.double("f46"),
            preClose = data.double("f60"),
            high = data.double("f44"),
            low = data.double("f45"),
            volume = data.double("f47"),
            amount = data.double("f48"),
            limitUp = data.double("f51"),
            limitDown = data.double("f52"),
            turnover = data.double("f168"),
            marketValue = data.double("f116"),
            circulationMarketValue = data.double("f117"),
        )
    }

    /**
     * 五档行情（买卖盘）。东方财富 push2 快照 API 字段映射（fltt=2）：
     *   买1: f19(价) f20(量)  买2: f17(价) f18(量)  买3: f15(价) f16(量)
     *   买4: f13(价) f14(量)  买5: f11(价) f12(量)
     *   卖1: f39(价) f40(量)  卖2: f37(价) f38(量)  卖3: f35(价) f36(量)
     *   卖4: f33(价) f34(量)  卖5: f31(价) f32(量)
     * 注意：必须请求完整字段列表，API 才返回买卖档数据
     */
    suspend fun fetchOrderBook(secId: String): OrderBookData = withContext(Dispatchers.IO) {
        val url = buildOrderBookUrl(secId)
        Log.d(TAG, "fetchOrderBook url=$url")
        val raw = executeGetSafe(url, retries = 2)
        Log.d(TAG, "fetchOrderBook raw=${raw.take(500)}")
        val root = parseRootObject(raw) ?: run {
            Log.w(TAG, "fetchOrderBook parseRootObject=null")
            return@withContext OrderBookData()
        }
        val data = root.obj("data") ?: run {
            Log.w(TAG, "fetchOrderBook data=null, root=$root")
            return@withContext OrderBookData()
        }

        // bids[0] = 买1, bids[4] = 买5
        val bids = listOf(
            OrderBookLevel(price = data.double("f19") ?: 0.0, volume = data.double("f20")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f17") ?: 0.0, volume = data.double("f18")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f15") ?: 0.0, volume = data.double("f16")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f13") ?: 0.0, volume = data.double("f14")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f11") ?: 0.0, volume = data.double("f12")?.toInt() ?: 0),
        )

        // asks[0] = 卖1, asks[4] = 卖5
        val asks = listOf(
            OrderBookLevel(price = data.double("f39") ?: 0.0, volume = data.double("f40")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f37") ?: 0.0, volume = data.double("f38")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f35") ?: 0.0, volume = data.double("f36")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f33") ?: 0.0, volume = data.double("f34")?.toInt() ?: 0),
            OrderBookLevel(price = data.double("f31") ?: 0.0, volume = data.double("f32")?.toInt() ?: 0),
        )

        Log.d(TAG, "fetchOrderBook bids=${bids.map { "${it.price}x${it.volume}" }}")
        Log.d(TAG, "fetchOrderBook asks=${asks.map { "${it.price}x${it.volume}" }}")

        OrderBookData(asks = asks, bids = bids)
    }

    suspend fun fetchTimeShare(target: ResolvedDetailTarget): List<TimeSharePoint> = withContext(Dispatchers.IO) {
        val url = buildTrendUrl(target.secId)
        val root = parseRootObject(executeGetSafe(url, retries = 2)) ?: return@withContext emptyList()
        val trendArray = root.obj("data")?.arr("trends") ?: return@withContext emptyList()

        trendArray.mapNotNull { entry ->
            val values = entry.asString.split(",")
            if (values.size < 7) return@mapNotNull null

            val price = values.getOrNull(1)?.toDoubleOrNull() ?: return@mapNotNull null
            val avg = values.getOrNull(2)?.toDoubleOrNull() ?: price
            val volume = values.getOrNull(5)?.toDoubleOrNull() ?: 0.0

            TimeSharePoint(
                time = values.firstOrNull().orEmpty(),
                price = price,
                avgPrice = avg,
                volume = volume,
            )
        }
    }

    suspend fun fetchKLine(target: ResolvedDetailTarget, klt: Int, limit: Int = 120): List<KLinePoint> =
        withContext(Dispatchers.IO) {
            val url = buildKLineUrl(target.secId, klt, limit)
            val root = parseRootObject(executeGetSafe(url, retries = 2)) ?: return@withContext emptyList()
            val klineArray = root.obj("data")?.arr("klines") ?: return@withContext emptyList()
            val total = klineArray.size()
            val start = (total - limit).coerceAtLeast(0)

            (start until total).mapNotNull { index ->
                val entry = klineArray.get(index)
                val values = entry.asString.split(",")
                if (values.size < 7) return@mapNotNull null

                val open = values.getOrNull(1)?.toDoubleOrNull() ?: return@mapNotNull null
                val close = values.getOrNull(2)?.toDoubleOrNull() ?: return@mapNotNull null
                val high = values.getOrNull(3)?.toDoubleOrNull() ?: return@mapNotNull null
                val low = values.getOrNull(4)?.toDoubleOrNull() ?: return@mapNotNull null
                val volume = values.getOrNull(5)?.toDoubleOrNull() ?: 0.0
                val amount = values.getOrNull(6)?.toDoubleOrNull() ?: 0.0

                KLinePoint(
                    time = values.firstOrNull().orEmpty(),
                    open = open,
                    close = close,
                    high = high,
                    low = low,
                    volume = volume,
                    amount = amount,
                )
            }
        }

    suspend fun fetchArticleNews(
        target: ResolvedDetailTarget,
        pageSize: Int = 20,
    ): List<DetailNewsItem> = withContext(Dispatchers.IO) {
        val callback = callback("jsonp")
        val url = buildArticleUrl(target.articleCode, callback, pageSize)
        val root = parseRootObject(executeGetSafe(url, retries = 2)) ?: return@withContext emptyList()
        val rawList = root.arr("re") ?: return@withContext emptyList()
        val expectedBarCodes = expectedBarCodes(target)

        val mapped = rawList.mapNotNull { node ->
            val item = node.asJsonObject
            val title = item.str("post_title")
            if (title.isBlank()) return@mapNotNull null

            val postId = item.str("post_id")
            val stockBarCode = item.str("stockbar_code")
            val urlValue = buildArticleDetailUrl(item, stockBarCode, postId)

            DetailNewsItem(
                id = postId.ifBlank { "${stockBarCode}_${title.hashCode()}" },
                title = title,
                summary = item.str("post_title"),
                time = item.str("post_display_time").ifBlank { item.str("post_publish_time") },
                source = item.str("stockbar_name").ifBlank { item.str("user_nickname") },
                url = urlValue,
            )
        }

        val filtered = mapped.filter {
            val url = it.url
            expectedBarCodes.any { code ->
                code.isNotBlank() && (url.contains(code, ignoreCase = true) || it.source.contains(code))
            }
        }

        (if (filtered.isNotEmpty()) filtered else mapped).take(pageSize)
    }

    suspend fun fetchFastNews(pageSize: Int = 20): List<DetailNewsItem> = withContext(Dispatchers.IO) {
        val root = parseRootObject(executeGetSafe(FAST_NEWS_URL, retries = 2)) ?: return@withContext emptyList()

        val newsArray = when {
            root.has("news") -> root.arr("news")
            root.obj("result")?.has("cmsArticleWebOld") == true -> root.obj("result")?.arr("cmsArticleWebOld")
            else -> null
        } ?: return@withContext emptyList()

        newsArray.mapNotNull { node ->
            val item = node.asJsonObject
            val title = item.str("title").ifBlank { item.str("simtitle") }
            if (title.isBlank()) return@mapNotNull null

            val id = item.str("id").ifBlank { item.str("newsid") }
            val digest = item.str("digest").ifBlank { title }
            val time = item.str("showtime").ifBlank { item.str("ordertime") }
            val url = item.str("url_w").ifBlank { item.str("url_unique") }
            val source = item.str("Art_Media_Name")

            DetailNewsItem(
                id = id.ifBlank { title.hashCode().toString() },
                title = title,
                summary = digest,
                time = time,
                source = source,
                url = url,
            )
        }.take(pageSize)
    }

    private fun expectedBarCodes(target: ResolvedDetailTarget): Set<String> {
        return buildSet {
            add(target.code)
            add(target.quoteCode)
            add(target.articleCode)
            add("sh${target.code}")
            add("sz${target.code}")
            add("zssh${target.code}")
            add("zssz${target.code}")
        }
    }

    private fun buildArticleDetailUrl(item: JsonObject, stockBarCode: String, postId: String): String {
        val artUniqueUrl = item.str("art_unique_url")
        if (artUniqueUrl.startsWith("http")) return artUniqueUrl
        if (stockBarCode.isNotBlank() && postId.isNotBlank()) {
            return "http://guba.eastmoney.com/news,$stockBarCode,$postId.html"
        }
        return "https://guba.eastmoney.com/"
    }

    private fun buildOrderBookUrl(secId: String): String {
        val ts = System.currentTimeMillis()
        val cb = "jQuery_$ts"
        // 必须使用完整字段列表，API 才返回买卖五档数据（f11-f20 买档，f31-f40 卖档）
        val fields = "f58,f734,f107,f57,f43,f59,f169,f301,f60,f170,f152,f177,f111," +
            "f46,f44,f45,f47,f260,f48,f261,f279,f277,f278,f288," +
            "f19,f17,f531,f15,f13,f11,f20,f18,f16,f14,f12," +
            "f39,f37,f35,f33,f31,f40,f38,f36,f34,f32"
        return "$SNAPSHOT_URL?invt=2&fltt=2&cb=$cb&fields=$fields" +
            "&secid=$secId&ut=$UT&wbp2u=%7C0%7C0%7C0%7Cweb&dect=1&_=$ts"
    }

    private fun buildSnapshotUrl(secId: String): String {
        return "$SNAPSHOT_URL?" +
            "secid=$secId&fltt=2&invt=2&ut=$UT&" +
            "fields=f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f116,f117,f168,f169,f170"
    }

    private fun buildTrendUrl(secId: String): String {
        return "$TREND_URL?" +
            "secid=$secId&fields1=f1,f2,f3,f4,f5,f6,f7,f8&" +
            "fields2=f51,f52,f53,f54,f55,f56,f57,f58&ndays=1&iscr=0"
    }

    private fun buildKLineUrl(secId: String, klt: Int, limit: Int): String {
        val callback = callback("jQuery")
        val ts = System.currentTimeMillis()
        return "$KLINE_URL?" +
            "cb=$callback&secid=$secId&ut=$UT&" +
            "fields1=f1,f2,f3,f4,f5,f6&" +
            "fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61&" +
            "klt=$klt&fqt=1&beg=0&end=20500101&lmt=$limit&_=$ts"
    }

    private fun buildArticleUrl(articleCode: String, callback: String, pageSize: Int): String {
        return "$ARTICLE_URL?" +
            "code=$articleCode&sorttype=1&ps=$pageSize&" +
            "from=CommonBaPost&deviceid=quoteweb&version=200&product=Guba&plat=Web&needzd=true&" +
            "callback=$callback"
    }

    private fun callback(prefix: String): String {
        return "${prefix}_${System.currentTimeMillis()}"
    }

    @Suppress("DEPRECATION")
    private fun parseRootObject(content: String): JsonObject? {
        val json = JsonpParser.unwrap(content)
        val element = runCatching { JsonParser().parse(json) }.getOrNull() ?: return null
        if (!element.isJsonObject) return null
        return element.asJsonObject
    }

    @Throws(IOException::class)
    private fun executeGet(url: String): String {
        val proxyUrl = EastMoneyMarketRepository.PROXY_BASE_URL
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
            .header("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
            .header("Connection", "close")
            .build()

        // When not using proxy, create a fresh client to avoid stale pooled connections
        val httpClient = if (proxyUrl.isEmpty()) buildFreshClient() else client
        val response = httpClient.newCall(request).execute()
        response.use { res ->
            if (!res.isSuccessful) {
                Log.e(TAG, "executeGet failed code=${res.code} url=$url")
                throw IOException("EastMoney request failed: ${res.code}")
            }
            val body = res.body?.string().orEmpty()
            if (body.isEmpty()) {
                Log.w(TAG, "executeGet empty body url=$url")
            }
            return body
        }
    }

    /**
     * Retry wrapper with exponential backoff + jitter.
     * Base delay doubles each attempt: 150ms → 300ms → 600ms → …
     * A small random jitter (0-100ms) is added to avoid thundering herd.
     */
    private suspend fun executeGetSafe(
        url: String,
        retries: Int = 1,
    ): String {
        var lastError: IOException? = null
        repeat(retries + 1) { attempt ->
            try {
                return executeGet(url)
            } catch (e: IOException) {
                lastError = e
                Log.w(TAG, "executeGetSafe attempt ${attempt + 1}/${retries + 1} failed: ${e.message}")
                if (attempt < retries) {
                    val baseDelay = 150L * (1 shl attempt) // 150, 300, 600, 1200 …
                    val jitter = (Math.random() * 100).toLong()
                    delay(baseDelay + jitter)
                }
            }
        }
        throw lastError ?: IOException("EastMoney request failed after ${retries + 1} attempts")
    }

    private fun JsonObject.obj(key: String): JsonObject? {
        val node = get(key) ?: return null
        if (!node.isJsonObject) return null
        return node.asJsonObject
    }

    private fun JsonObject.arr(key: String): JsonArray? {
        val node = get(key) ?: return null
        if (!node.isJsonArray) return null
        return node.asJsonArray
    }

    private fun JsonObject.str(key: String): String {
        val node = get(key) ?: return ""
        if (node.isJsonNull) return ""
        return runCatching { node.asString }.getOrDefault("")
    }

    private fun JsonObject.double(key: String): Double? {
        val node = get(key) ?: return null
        if (node.isJsonNull) return null
        return nodeToDouble(node)
    }

    private fun nodeToDouble(node: JsonElement): Double? {
        return runCatching { node.asDouble }.getOrElse {
            node.asString.toDoubleOrNull()
        }
    }

    companion object {
        private fun buildClient(): OkHttpClient {
            return OkHttpClient.Builder()
                .retryOnConnectionFailure(true)
                .connectTimeout(8, TimeUnit.SECONDS)
                .readTimeout(8, TimeUnit.SECONDS)
                .writeTimeout(8, TimeUnit.SECONDS)
                .callTimeout(12, TimeUnit.SECONDS)
                // 避免复用被服务端提前关闭的连接
                .connectionPool(ConnectionPool(0, 1, TimeUnit.SECONDS))
                // 规避部分网络对 HTTP/2 的异常处理
                .protocols(listOf(Protocol.HTTP_1_1))
                // 优先 IPv4，避免某些网络的 IPv6 黑洞
                .dns(PreferIpv4Dns)
                .build()
        }

        /**
         * Create a completely fresh OkHttpClient for direct (non-proxy) calls.
         * Each call gets its own connection pool so that we never hit a stale
         * connection that the server already closed.
         */
        private fun buildFreshClient(): OkHttpClient {
            return OkHttpClient.Builder()
                .retryOnConnectionFailure(true)
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .writeTimeout(10, TimeUnit.SECONDS)
                .callTimeout(15, TimeUnit.SECONDS)
                .connectionPool(ConnectionPool(0, 1, TimeUnit.SECONDS))
                .protocols(listOf(Protocol.HTTP_1_1))
                .dns(PreferIpv4Dns)
                .build()
        }

        private val PreferIpv4Dns = object : Dns {
            override fun lookup(hostname: String): List<InetAddress> {
                val addresses = Dns.SYSTEM.lookup(hostname)
                val ipv4 = addresses.filterIsInstance<Inet4Address>()
                return if (ipv4.isNotEmpty()) ipv4 else addresses
            }
        }

        private const val SNAPSHOT_URL = "https://push2.eastmoney.com/api/qt/stock/get"
        private const val TREND_URL = "https://push2his.eastmoney.com/api/qt/stock/trends2/get"
        private const val KLINE_URL = "https://push2his.eastmoney.com/api/qt/stock/kline/get"
        private const val ARTICLE_URL = "https://gbapi.eastmoney.com/webarticlelist/api/Article/Articlelist"
        private const val FAST_NEWS_URL = "https://newsinfo.eastmoney.com/kuaixun/v2/api/list"
        private const val TAG = "zs_ts"
        private const val UT = "fa5fd1943c7b386f172d6893dbfba10b"
        private const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36"
    }
}
