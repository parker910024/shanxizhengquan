package com.yanshu.app.ui.hq

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yanshu.app.data.IPOGroup
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.eastmoney.EastMoneyMarketRepository
import com.yanshu.app.ui.hq.model.FundFlowInfo
import com.yanshu.app.ui.hq.model.IndexData
import com.yanshu.app.ui.hq.model.IpoData
import com.yanshu.app.ui.hq.model.MarketDistribution
import com.yanshu.app.ui.hq.model.SectorData
import com.yanshu.app.ui.hq.model.StockData
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.launch

class HqViewModel : ViewModel() {

    private val emRepository = EastMoneyMarketRepository()

    // ────────────── 指数快照 + 走势图 ──────────────

    private val _indexList = MutableLiveData<List<IndexData>>(emptyList())
    val indexList: LiveData<List<IndexData>> = _indexList

    /** code -> 价格序列（东方财富 trends2 API） */
    private val _indexSparklines = MutableLiveData<Map<String, List<Float>>>(emptyMap())
    val indexSparklines: LiveData<Map<String, List<Float>>> = _indexSparklines

    // ────────────── 股票排行榜 ──────────────

    private val _stockList = MutableLiveData<List<StockData>>(emptyList())
    val stockList: LiveData<List<StockData>> = _stockList

    /** 0=空闲, 1=加载中, 2=没有更多 */
    private val _stockLoadState = MutableLiveData(0)
    val stockLoadState: LiveData<Int> = _stockLoadState

    private var stockPage = 1
    private val stockPageSize = 50
    private var isStockLoading = false
    private var stockHasMore = true
    private val accumulatedStocks = mutableListOf<StockData>()

    // ────────────── 新股申购 ──────────────

    private val _ipoList = MutableLiveData<List<IpoData>>(emptyList())
    val ipoList: LiveData<List<IpoData>> = _ipoList

    // ────────────── 板块 ──────────────

    private val _industrySectors = MutableLiveData<List<SectorData>>(emptyList())
    val industrySectors: LiveData<List<SectorData>> = _industrySectors

    private val _conceptSectors = MutableLiveData<List<SectorData>>(emptyList())
    val conceptSectors: LiveData<List<SectorData>> = _conceptSectors

    // ────────────── 涨跌家数（驱动进度条） ──────────────

    /** Triple(上涨家数, 下跌家数, 平盘家数) */
    private val _riseCount = MutableLiveData<Triple<Int, Int, Int>>()
    val riseCount: LiveData<Triple<Int, Int, Int>> = _riseCount

    // ────────────── 涨跌分布（驱动柱状图） ──────────────

    private val _marketDistribution = MutableLiveData<MarketDistribution>()
    val marketDistribution: LiveData<MarketDistribution> = _marketDistribution

    // ────────────── 资金流向 ──────────────

    private val _fundFlow = MutableLiveData<List<FundFlowInfo>>(emptyList())
    val fundFlow: LiveData<List<FundFlowInfo>> = _fundFlow

    // ────────────── 当前股票列表市场类型 ──────────────

    private var currentStockMarket = "shenhu"

    // ────────────── 公开接口 ──────────────

    /**
     * 初次加载：所有模块并发拉取
     */
    fun loadAll() {
        loadIndex()
        loadStockList(currentStockMarket)
        loadIpoList()
        loadSectors()
        loadRiseCount()
        loadFundFlow()
    }

    /**
     * 切换股票排行榜市场（沪深/创业/北证/科创）
     */
    fun switchStockMarket(market: String) {
        currentStockMarket = market
        resetStockPagination()
        loadStockList(market)
    }

    /**
     * 加载更多股票（分页）
     */
    fun loadMoreStocks() {
        if (isStockLoading || !stockHasMore) return
        stockPage++
        loadStockList(currentStockMarket, append = true)
    }

    private fun resetStockPagination() {
        stockPage = 1
        isStockLoading = false
        stockHasMore = true
        accumulatedStocks.clear()
        _stockLoadState.value = 0
    }

    /**
     * 刷新指数快照 + 走势图（定时轮询调用）
     */
    fun refreshIndex() {
        loadIndex()
    }

    // ────────────── 私有加载方法 ──────────────

    private fun loadIndex() {
        viewModelScope.launch {
            val result = runCatching { Remote.callApi { getIndexMarket() } }.getOrNull()
            val items = result?.data?.list ?: return@launch

            val indexDataList = items.mapNotNull { item ->
                val arr = item.allcodes_arr
                if (arr.size < 6) return@mapNotNull null
                val price = arr.getOrNull(3)?.toDoubleOrNull() ?: return@mapNotNull null
                val change = arr.getOrNull(4)?.toDoubleOrNull() ?: 0.0
                val changePct = arr.getOrNull(5)?.toDoubleOrNull() ?: 0.0
                val marketHint = when {
                    item.allcode.startsWith("sh", ignoreCase = true) -> "sh"
                    item.allcode.startsWith("bj", ignoreCase = true) -> "bj"
                    else -> "sz"
                }

                IndexData(
                    name = item.title,
                    value = price,
                    change = change,
                    changePercent = changePct,
                    isUp = change >= 0,
                    code = item.code,
                    marketHint = marketHint,
                )
            }
            _indexList.value = indexDataList

            // 并发拉取所有指数走势图
            loadSparklines(items.map { item ->
                val prefix = if (item.allcode.startsWith("sh")) "1" else "0"
                item.code to "$prefix.${item.code}"
            })
        }
    }

    private suspend fun loadSparklines(codeSecIdPairs: List<Pair<String, String>>) {
        val sparklines = codeSecIdPairs.map { (code, secId) ->
            viewModelScope.async {
                val prices = runCatching {
                    emRepository.fetchIndexSparkline(secId)
                }.getOrDefault(emptyList())
                code to prices
            }
        }.awaitAll().toMap()

        _indexSparklines.value = sparklines
    }

    private fun loadStockList(market: String, append: Boolean = false) {
        if (isStockLoading) return
        isStockLoading = true
        if (append) _stockLoadState.value = 1

        viewModelScope.launch {
            val page = stockPage
            val result = runCatching {
                Remote.callApi {
                    when (market) {
                        "cy" -> getCyList(page = page, size = stockPageSize)
                        "bj" -> getBjList(page = page, size = stockPageSize)
                        "kc" -> getKcList(page = page, size = stockPageSize)
                        else -> getShenhuList(page = page, size = stockPageSize)
                    }
                }
            }.getOrNull()

            isStockLoading = false

            val items = result?.data?.list
            if (items == null) {
                if (append) {
                    stockPage--
                    _stockLoadState.value = 0
                }
                return@launch
            }

            val newStocks = items.mapNotNull { item ->
                val price = item.trade.toDoubleOrNull() ?: return@mapNotNull null
                val change = item.pricechange.toDoubleOrNull() ?: 0.0
                val changePct = item.changepercent.toDoubleOrNull() ?: 0.0
                val volume = item.buy
                val prevClose = item.settlement.toDoubleOrNull() ?: 0.0
                val open = item.open.toDoubleOrNull() ?: 0.0
                val symbol = item.symbol
                val marketPrefix = symbol.take(2).lowercase()

                StockData(
                    name = item.name,
                    code = item.code,
                    market = marketPrefix,
                    price = price,
                    change = change,
                    changePercent = changePct,
                    volume = formatVolume(volume),
                    turnover = 0.0,
                    prevClose = prevClose,
                    open = open,
                    high = 0.0,
                    isUp = change >= 0,
                )
            }

            if (append) {
                val existedKeys = accumulatedStocks
                    .asSequence()
                    .map { "${it.market}_${it.code}" }
                    .toHashSet()
                var appendCount = 0
                newStocks.forEach { stock ->
                    if (existedKeys.add("${stock.market}_${stock.code}")) {
                        accumulatedStocks.add(stock)
                        appendCount++
                    }
                }
                if (newStocks.isEmpty() || appendCount == 0) {
                    stockHasMore = false
                }
            } else {
                accumulatedStocks.clear()
                val firstPage = newStocks.distinctBy { "${it.market}_${it.code}" }
                accumulatedStocks.addAll(firstPage)
                stockHasMore = firstPage.isNotEmpty()
            }
            _stockList.value = accumulatedStocks.toList()
            _stockLoadState.value = if (!stockHasMore && append) 2 else 0
        }
    }

    private fun loadIpoList() {
        viewModelScope.launch {
            val result = runCatching { Remote.callApi { getIpoList(page = 1, type = 0) } }.getOrNull()
            val groups: List<IPOGroup> = result?.data?.list ?: return@launch

            val ipoList = groups.flatMap { group ->
                group.sub_info.map { item ->
                    IpoData(
                        name = item.name,
                        code = item.code,
                        market = item.getMarketTag(),
                        issuePrice = item.fx_price.toDoubleOrNull() ?: 0.0,
                        peRatio = item.fx_rate.toDoubleOrNull() ?: 0.0,
                        board = item.getMarketTag(),
                        fxNum = item.fx_num,
                        wsfxNum = item.wsfx_num,
                        sgLimit = item.sg_limit,
                        sgDate = item.sg_date,
                        ssDate = item.ss_date,
                        zqRate = item.zq_rate,
                        industry = item.industry,
                    )
                }
            }
            _ipoList.value = ipoList
        }
    }

    private fun loadSectors() {
        viewModelScope.launch {
            val industryDeferred = async {
                runCatching { emRepository.fetchSectorList(2) }.getOrDefault(emptyList())
            }
            val conceptDeferred = async {
                runCatching { emRepository.fetchSectorList(3) }.getOrDefault(emptyList())
            }
            _industrySectors.value = industryDeferred.await()
            _conceptSectors.value = conceptDeferred.await()
        }
    }

    private fun loadRiseCount() {
        viewModelScope.launch {
            val result = runCatching { emRepository.fetchRiseCount() }.getOrNull()
            if (result != null) {
                _riseCount.value = result.first
                _marketDistribution.value = result.second
            }
        }
    }

    private fun loadFundFlow() {
        viewModelScope.launch {
            val flow = runCatching { emRepository.fetchFundFlow() }.getOrDefault(emptyList())
            if (flow.isNotEmpty()) _fundFlow.value = flow
        }
    }

    // ────────────── 格式化工具 ──────────────

    private fun formatVolume(raw: String): String {
        val v = raw.toLongOrNull() ?: return raw
        return when {
            v >= 100_000_000L -> String.format("%.2f亿", v / 100_000_000.0)
            v >= 10_000L -> String.format("%.2f万", v / 10_000.0)
            else -> v.toString()
        }
    }
}
