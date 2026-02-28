package com.yanshu.app.ui.hq.detail.model

enum class DetailChartTab {
    TIME,
    FIVE_MIN,
    DAY_K,
    WEEK_MONTH,
}

enum class WeekMonthMode(val klt: Int, val label: String) {
    WEEK(102, "周K"),
    MONTH(103, "月K"),
}

enum class DetailNewsTab(val title: String) {
    DYNAMIC("动态"),
    FAST_24("7X24"),
    MARKET("盘面"),
    ADVISER("投顾"),
    IMPORTANT("要闻"),
}

enum class ChartRenderType {
    TIME_SHARE,
    K_LINE,
}

data class ResolvedDetailTarget(
    val rawCode: String,
    val code: String,
    val secId: String,
    val quoteCode: String,
    val articleCode: String,
    val isIndex: Boolean,
)

data class SnapshotData(
    val code: String = "",
    val name: String = "",
    val price: Double? = null,
    val change: Double? = null,
    val changePct: Double? = null,
    val open: Double? = null,
    val preClose: Double? = null,
    val high: Double? = null,
    val low: Double? = null,
    val volume: Double? = null,
    val amount: Double? = null,
    val limitUp: Double? = null,
    val limitDown: Double? = null,
    val turnover: Double? = null,
    val marketValue: Double? = null,
    val circulationMarketValue: Double? = null,
) {
    val amplitudePct: Double?
        get() {
            val highValue = high ?: return null
            val lowValue = low ?: return null
            val preCloseValue = preClose ?: return null
            if (preCloseValue == 0.0) return null
            return (highValue - lowValue) / preCloseValue * 100.0
        }
}

data class TimeSharePoint(
    val time: String,
    val price: Double,
    val avgPrice: Double,
    val volume: Double,
)

data class KLinePoint(
    val time: String,
    val open: Double,
    val close: Double,
    val high: Double,
    val low: Double,
    val volume: Double,
    val amount: Double,
)

data class DetailNewsItem(
    val id: String,
    val title: String,
    val summary: String,
    val time: String,
    val source: String,
    val url: String,
)

data class ChartPayload(
    val renderType: ChartRenderType,
    val timeSharePoints: List<TimeSharePoint> = emptyList(),
    val kLinePoints: List<KLinePoint> = emptyList(),
    val weekMonthMode: WeekMonthMode = WeekMonthMode.WEEK,
)

data class OrderBookLevel(
    val price: Double,
    val volume: Int,
)

data class OrderBookData(
    val asks: List<OrderBookLevel> = emptyList(),
    val bids: List<OrderBookLevel> = emptyList(),
)

data class StockDetailViewState(
    val title: String = "--",
    val code: String = "--",
    val snapshot: SnapshotData = SnapshotData(),
    val chartTab: DetailChartTab = DetailChartTab.TIME,
    val weekMonthMode: WeekMonthMode = WeekMonthMode.WEEK,
    val newsTab: DetailNewsTab = DetailNewsTab.DYNAMIC,
    val favorite: Boolean = false,
    val isIndex: Boolean = false,
    val tradeEnabled: Boolean = true,
    val quoteCode: String = "",
)
