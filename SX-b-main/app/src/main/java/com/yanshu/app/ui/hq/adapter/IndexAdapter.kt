package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemHqIndexBinding
import com.yanshu.app.ui.hq.model.IndexData
import com.yanshu.app.ui.hq.view.IndexSparklineView
import ex.ss.lib.base.adapter.BaseItemAdapter

class IndexAdapter(
    private val onItemClick: ((IndexData) -> Unit)? = null,
) : BaseItemAdapter<IndexData, ItemHqIndexBinding>() {

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemHqIndexBinding {
        return ItemHqIndexBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemHqIndexBinding, position: Int) {
        val data = getItem(position)
        val textColor = if (data.isUp) {
            getColor(R.color.hq_rise_color)
        } else {
            getColor(R.color.hq_fall_color)
        }

        binding.layoutIndexCard.setBackgroundResource(
            if (data.isUp) R.drawable.bg_index_card_rise else R.drawable.bg_index_card_fall,
        )

        binding.tvIndexName.text = data.name
        binding.tvIndexValue.text = String.format("%.2f", data.value)
        binding.tvIndexValue.setTextColor(textColor)

        val changeSign = if (data.change >= 0) "+" else ""
        binding.tvIndexChange.text = String.format(
            "%s%.2f  %s%.2f%%",
            changeSign, data.change,
            changeSign, data.changePercent,
        )
        binding.tvIndexChange.setTextColor(textColor)

        // 迷你走势图：从东方财富 trends2 API 获取的真实价格点
        // 使用 <view class="..."> 写法绕过 DataBinding 解析器兼容问题，需手动强转
        (binding.viewChart as? IndexSparklineView)?.setData(data.sparklinePrices, data.isUp)

        binding.root.setOnClickListener {
            onItemClick?.invoke(data)
            callItemClick(data, position)
        }
    }
}
