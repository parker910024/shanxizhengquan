package com.yanshu.app.ui.hq.model

import ex.ss.lib.base.adapter.data.BaseItem

data class IndexData(
    val name: String,
    val value: Double,
    val change: Double,
    val changePercent: Double,
    val isUp: Boolean,
    val code: String = "",
    val marketHint: String = "",
    val sparklinePrices: List<Float> = emptyList(),
) : BaseItem

data class SectorData(
    val name: String,
    val changePercent: Double,
    val topStock: String,
    val topStockChange: Double,
    val isUp: Boolean,
) : BaseItem

data class StockData(
    val name: String,
    val code: String,
    val market: String,
    val price: Double,
    val change: Double,
    val changePercent: Double,
    val volume: String,
    val turnover: Double,
    val prevClose: Double,
    val open: Double,
    val high: Double,
    val isUp: Boolean,
) : BaseItem

data class MarketOverview(
    val riseStop: Int,
    val fallStop: Int,
    val rise: Int,
    val fall: Int,
    val flat: Int,
)

data class FundFlowInfo(
    val label: String,
    val value: String,
    val isPositive: Boolean,
)

data class IpoData(
    val name: String,
    val code: String,
    val market: String,
    val issuePrice: Double,
    val peRatio: Double,
    val board: String,
    val fxNum: String = "0",
    val wsfxNum: String = "0",
    val sgLimit: String = "0",
    val sgDate: String = "",
    val ssDate: String = "",
    val zqRate: String = "0",
    val industry: String = "",
) : BaseItem

data class FavoriteData(
    val name: String,
    val code: String,
    val market: String,
    val price: Double,
    val changePercent: Double,
    val changeAmount: Double,
    val isUp: Boolean,
    val isIndex: Boolean = false,
) : BaseItem

data class MarketDistribution(
    val riseStop: Int,
    val rise7: Int,
    val rise5to7: Int,
    val rise3to5: Int,
    val rise0to3: Int,
    val flat: Int,
    val fall0to3: Int,
    val fall3to5: Int,
    val fall5to7: Int,
    val fall7: Int,
    val fallStop: Int,
) {
    val totalRise: Int get() = riseStop + rise7 + rise5to7 + rise3to5 + rise0to3
    val totalFall: Int get() = fall0to3 + fall3to5 + fall5to7 + fall7 + fallStop

    fun toList(): List<Int> = listOf(
        riseStop,
        rise7,
        rise5to7,
        rise3to5,
        rise0to3,
        flat,
        fall0to3,
        fall3to5,
        fall5to7,
        fall7,
        fallStop,
    )

    fun maxValue(): Int = toList().maxOrNull() ?: 1
}
