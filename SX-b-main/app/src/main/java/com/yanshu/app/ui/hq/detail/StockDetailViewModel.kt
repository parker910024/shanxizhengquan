package com.yanshu.app.ui.hq.detail

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yanshu.app.data.FavoriteRequest
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.sina.SinaStockRepository
import com.yanshu.app.repo.eastmoney.SecIdResolver
import com.yanshu.app.ui.hq.detail.model.ChartPayload
import com.yanshu.app.ui.hq.detail.model.ChartRenderType
import com.yanshu.app.ui.hq.detail.model.DetailChartTab
import com.yanshu.app.ui.hq.detail.model.DetailNewsTab
import com.yanshu.app.ui.hq.detail.model.OrderBookData
import com.yanshu.app.ui.hq.detail.model.ResolvedDetailTarget
import com.yanshu.app.ui.hq.detail.model.SnapshotData
import com.yanshu.app.ui.hq.detail.model.StockDetailViewState
import com.yanshu.app.ui.hq.detail.model.WeekMonthMode
import kotlinx.coroutines.launch

class StockDetailViewModel : ViewModel() {

    private val repository = SinaStockRepository()

    private var target: ResolvedDetailTarget? = null
    private var initToken: String? = null

    private val chartCache = mutableMapOf<String, ChartPayload>()

    private val _viewState = MutableLiveData(StockDetailViewState())
    val viewState: LiveData<StockDetailViewState> = _viewState

    private val _chartPayload = MutableLiveData<ChartPayload>()
    val chartPayload: LiveData<ChartPayload> = _chartPayload

    private val _loadingChart = MutableLiveData(false)
    val loadingChart: LiveData<Boolean> = _loadingChart

    private val _message = MutableLiveData<String>()
    val message: LiveData<String> = _message

    private val _orderBook = MutableLiveData<OrderBookData>()
    val orderBook: LiveData<OrderBookData> = _orderBook

    fun initialize(
        code: String,
        name: String,
        marketHint: String?,
        isIndex: Boolean,
    ) {
        val newTarget = SecIdResolver.resolve(code, marketHint, isIndex)
        val token = "${newTarget.secId}|${newTarget.quoteCode}|$isIndex|$name"
        if (token == initToken) return
        initToken = token
        target = newTarget
        chartCache.clear()

        Log.d(TAG, "initialize code=$code name=$name isIndex=$isIndex secId=${newTarget.secId}")

        _viewState.value = StockDetailViewState(
            title = if (name.isBlank()) newTarget.code else name,
            code = newTarget.code,
            favorite = false,
            isIndex = isIndex,
            tradeEnabled = !isIndex,
            quoteCode = newTarget.quoteCode,
        )

        refreshSnapshot(showError = true)
        loadChart(force = true)
        loadFavoriteStatus()
    }

    fun refreshSnapshot(showError: Boolean = false) {
        val currentTarget = target ?: return
        Log.d(TAG, "refreshSnapshot secId=${currentTarget.secId} isIndex=${_viewState.value?.isIndex}")
        viewModelScope.launch {
            val previous = _viewState.value?.snapshot ?: SnapshotData()
            val latest = runCatching { repository.fetchSnapshot(currentTarget) }.getOrElse {
                Log.e(TAG, "fetchSnapshot error", it)
                null
            }
            Log.d(TAG, "fetchSnapshot result: price=${latest?.price} name=${latest?.name} change=${latest?.change}")
            if (latest == null) {
                return@launch
            }
            val merged = mergeSnapshot(previous, latest)
            updateState {
                copy(
                    title = if (merged.name.isNotBlank()) merged.name else title,
                    code = if (merged.code.isNotBlank()) merged.code else code,
                    snapshot = merged,
                )
            }
            // 非指数才拉五档行情
            if (_viewState.value?.isIndex == false) {
                refreshOrderBook(currentTarget)
            }
        }
    }

    private suspend fun refreshOrderBook(currentTarget: ResolvedDetailTarget) {
        Log.d(TAG, "refreshOrderBook secId=${currentTarget.secId}")
        val book = runCatching { repository.fetchOrderBook(currentTarget.secId) }.getOrElse {
            Log.e(TAG, "fetchOrderBook error", it)
            null
        } ?: return
        Log.d(TAG, "fetchOrderBook result: asks=${book.asks.map { "${it.price}x${it.volume}" }} bids=${book.bids.map { "${it.price}x${it.volume}" }}")
        _orderBook.postValue(book)
    }

    fun onTimeTabClick() {
        updateState {
            copy(chartTab = DetailChartTab.TIME)
        }
        loadChart(force = false)
    }

    fun onFiveMinTabClick() {
        updateState {
            copy(chartTab = DetailChartTab.FIVE_MIN)
        }
        loadChart(force = false)
    }

    fun onDayKTabClick() {
        updateState {
            copy(chartTab = DetailChartTab.DAY_K)
        }
        loadChart(force = false)
    }

    fun onWeekMonthTabClick() {
        val state = _viewState.value ?: return
        if (state.chartTab == DetailChartTab.WEEK_MONTH) {
            val nextMode = if (state.weekMonthMode == WeekMonthMode.WEEK) {
                WeekMonthMode.MONTH
            } else {
                WeekMonthMode.WEEK
            }
            updateState {
                copy(weekMonthMode = nextMode)
            }
        } else {
            updateState {
                copy(chartTab = DetailChartTab.WEEK_MONTH)
            }
        }
        loadChart(force = false)
    }

    private fun loadChart(force: Boolean) {
        val state = _viewState.value ?: return
        val currentTarget = target ?: return

        val cacheKey = when (state.chartTab) {
            DetailChartTab.TIME -> "time"
            DetailChartTab.FIVE_MIN -> "k_5"
            DetailChartTab.DAY_K -> "k_101"
            DetailChartTab.WEEK_MONTH -> "k_${state.weekMonthMode.klt}"
        }

        if (!force) {
            chartCache[cacheKey]?.let {
                _chartPayload.value = it
                return
            }
        }

        viewModelScope.launch {
            _loadingChart.value = true
            val payload = runCatching {
                when (state.chartTab) {
                    DetailChartTab.TIME -> {
                        val points = repository.fetchTimeShare(currentTarget)
                        ChartPayload(
                            renderType = ChartRenderType.TIME_SHARE,
                            timeSharePoints = points,
                            weekMonthMode = state.weekMonthMode,
                        )
                    }

                    DetailChartTab.FIVE_MIN -> {
                        val points = repository.fetchKLine(currentTarget, 5)
                        ChartPayload(
                            renderType = ChartRenderType.K_LINE,
                            kLinePoints = points,
                            weekMonthMode = state.weekMonthMode,
                        )
                    }

                    DetailChartTab.DAY_K -> {
                        val points = repository.fetchKLine(currentTarget, 101)
                        ChartPayload(
                            renderType = ChartRenderType.K_LINE,
                            kLinePoints = points,
                            weekMonthMode = state.weekMonthMode,
                        )
                    }

                    DetailChartTab.WEEK_MONTH -> {
                        val points = repository.fetchKLine(currentTarget, state.weekMonthMode.klt)
                        ChartPayload(
                            renderType = ChartRenderType.K_LINE,
                            kLinePoints = points,
                            weekMonthMode = state.weekMonthMode,
                        )
                    }
                }
            }.getOrNull()

            _loadingChart.value = false
            if (payload == null) {
                return@launch
            }

            chartCache[cacheKey] = payload
            _chartPayload.value = payload
        }
    }

    fun onNewsTabClick(newsTab: DetailNewsTab) {
        updateState { copy(newsTab = newsTab) }
    }

    private fun loadFavoriteStatus() {
        val currentTarget = target ?: return
        viewModelScope.launch {
            val result = runCatching {
                Remote.callApi { getHqInfo(currentTarget.quoteCode) }
            }.getOrNull()
            val isFavorite = result?.data?.is_zx == 1
            updateState { copy(favorite = isFavorite) }
        }
    }

    fun toggleFavorite() {
        val currentTarget = target ?: return
        val state = _viewState.value ?: return
        val willFavorite = !state.favorite
        updateState { copy(favorite = willFavorite) }
        viewModelScope.launch {
            val request = FavoriteRequest(
                allcode = currentTarget.quoteCode,
                code = currentTarget.code,
            )
            val result = runCatching {
                if (willFavorite) {
                    Remote.callApi { addFavorite(request) }
                } else {
                    Remote.callApi { removeFavorite(request) }
                }
            }.getOrNull()
            if (result == null || !result.isSuccess()) {
                // 服务端失败则回滚 UI
                updateState { copy(favorite = !willFavorite) }
                _message.value = if (willFavorite) "加入自选失败" else "取消自选失败"
            } else {
                _message.value = if (willFavorite) "加入自选成功" else "取消自选成功"
            }
        }
    }

    fun currentTradePayload(): Pair<String, Double?> {
        val state = _viewState.value ?: StockDetailViewState()
        return state.quoteCode to state.snapshot.price
    }

    fun isIndex(): Boolean = _viewState.value?.isIndex == true

    private fun mergeSnapshot(old: SnapshotData, latest: SnapshotData): SnapshotData {
        return SnapshotData(
            code = latest.code.ifBlank { old.code },
            name = latest.name.ifBlank { old.name },
            price = latest.price ?: old.price,
            change = latest.change ?: old.change,
            changePct = latest.changePct ?: old.changePct,
            open = latest.open ?: old.open,
            preClose = latest.preClose ?: old.preClose,
            high = latest.high ?: old.high,
            low = latest.low ?: old.low,
            volume = latest.volume ?: old.volume,
            amount = latest.amount ?: old.amount,
            limitUp = latest.limitUp ?: old.limitUp,
            limitDown = latest.limitDown ?: old.limitDown,
            turnover = latest.turnover ?: old.turnover,
            marketValue = latest.marketValue ?: old.marketValue,
            circulationMarketValue = latest.circulationMarketValue ?: old.circulationMarketValue,
        )
    }

    private fun updateState(block: StockDetailViewState.() -> StockDetailViewState) {
        val current = _viewState.value ?: StockDetailViewState()
        _viewState.value = current.block()
    }

    companion object {
        private const val TAG = "zs_ts"
    }
}
