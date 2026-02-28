package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.HorizontalScrollView
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemHqStockBinding
import com.yanshu.app.ui.hq.model.StockData
import ex.ss.lib.base.adapter.BaseItemAdapter

class StockAdapter(
    private val onScrollChange: ((Int) -> Unit)? = null,
    private val onItemClick: ((StockData) -> Unit)? = null
) : BaseItemAdapter<StockData, ItemHqStockBinding>() {

    private var syncScrollX = 0
    private val scrollViews = mutableListOf<HorizontalScrollView>()
    
    // 列宽度 (dp): 现价80, 涨跌70, 涨跌幅70, 成交额100, 换手率70, 昨收80, 今开80, 最高80
    private val columnWidths = listOf(80, 70, 70, 100, 70, 80, 80, 80)

    fun scrollToColumn(columnIndex: Int) {
        val density = scrollViews.firstOrNull()?.context?.resources?.displayMetrics?.density ?: 1f
        // 计算到该列的起始位置
        val scrollX = columnWidths.take(columnIndex).sum() * density
        syncScrollX = scrollX.toInt()
        scrollViews.forEach { it.smoothScrollTo(syncScrollX, 0) }
    }

    fun syncAllScrollViews(scrollX: Int) {
        syncScrollX = scrollX
        scrollViews.forEach { it.scrollTo(scrollX, 0) }
    }

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemHqStockBinding {
        return ItemHqStockBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemHqStockBinding, position: Int) {
        val data = getItem(position)
        val priceColor = when {
            data.isUp -> getColor(R.color.hq_rise_color)
            data.change < 0 -> getColor(R.color.hq_fall_color)
            else -> getColor(R.color.hq_flat_color)
        }

        binding.tvStockName.text = data.name
        binding.tvStockCode.text = data.code
        binding.tvMarketTag.text = data.market

        // 设置市场标签颜色
        val marketColor = when {
            data.market.contains("沪") || data.market.contains("娌") || data.code.startsWith("6") -> {
                getColor(R.color.hq_indicator_color)
            }

            data.market.contains("深") || data.market.contains("娣") || data.code.startsWith("0") || data.code.startsWith("3") -> {
                getColor(R.color.hq_rise_color)
            }

            data.market.contains("北") || data.market.contains("鍖") || data.code.startsWith("8") || data.code.startsWith("4") -> {
                getColor(R.color.hq_fall_color)
            }

            else -> getColor(R.color.hq_text_gray)
        }
        binding.tvMarketTag.setTextColor(marketColor)

        // 价格相关列
        binding.tvPrice.text = String.format("%.2f", data.price)
        binding.tvPrice.setTextColor(priceColor)

        val changeSign = if (data.change >= 0) "+" else ""
        binding.tvChange.text = String.format("%s%.2f", changeSign, data.change)
        binding.tvChange.setTextColor(priceColor)

        binding.tvChangePct.text = String.format("%s%.2f%%", changeSign, data.changePercent)
        binding.tvChangePct.setTextColor(priceColor)

        // 其他数据列
        binding.tvVolume.text = data.volume
        binding.tvTurnover.text = String.format("%.2f%%", data.turnover)
        binding.tvPrevClose.text = String.format("%.2f", data.prevClose)
        binding.tvOpen.text = String.format("%.2f", data.open)
        binding.tvHigh.text = String.format("%.2f", data.high)

        // 设置滚动监听和同步
        setupScrollSync(binding)

        binding.root.setOnClickListener {
            onItemClick?.invoke(data)
            callItemClick(data, position)
        }
    }

    private fun setupScrollSync(binding: ItemHqStockBinding) {
        val scrollView = binding.hsvStockData
        
        // 添加到列表
        if (!scrollViews.contains(scrollView)) {
            scrollViews.add(scrollView)
        }
        
        // 同步当前滚动位置
        scrollView.scrollTo(syncScrollX, 0)
        
        // 设置滚动监听
        scrollView.setOnScrollChangeListener { _, scrollX, _, _, _ ->
            if (scrollX != syncScrollX) {
                syncScrollX = scrollX
                scrollViews.forEach { 
                    if (it != scrollView) {
                        it.scrollTo(scrollX, 0)
                    }
                }
                onScrollChange?.invoke(scrollX)
            }
        }
    }

    override fun onViewRecycled(holder: ex.ss.lib.base.adapter.BaseViewHolder<ItemHqStockBinding>) {
        super.onViewRecycled(holder)
        scrollViews.remove(holder.binding.hsvStockData)
    }
}
