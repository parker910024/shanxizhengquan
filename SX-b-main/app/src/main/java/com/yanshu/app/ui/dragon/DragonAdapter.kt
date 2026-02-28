package com.yanshu.app.ui.dragon

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemDragonBinding
import ex.ss.lib.base.adapter.BaseItemAdapter

class DragonAdapter(
    private val onItemClick: (DragonItem) -> Unit = {},
) : BaseItemAdapter<DragonItem, ItemDragonBinding>() {

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemDragonBinding {
        return ItemDragonBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemDragonBinding, position: Int) {
        val item = getItem(position)
        binding.root.setOnClickListener { onItemClick(item) }

        binding.tvName.text = item.name
        binding.tvCode.text = item.code
        binding.tvClosePrice.text = String.format("%.2f", item.closePrice)

        // 市场标签：sh→沪，sz→深
        val marketLabel = when (item.market?.lowercase()) {
            "sh" -> "沪"
            "sz" -> "深"
            else -> item.market ?: ""
        }
        binding.tvMarket.text = marketLabel
        binding.tvMarket.visibility = if (marketLabel.isNotEmpty()) View.VISIBLE else View.GONE

        // 净买入 (亿)
        val netBuyText = String.format("%.2f亿", item.netBuy)
        binding.tvNetBuy.text = netBuyText

        // 涨跌幅
        val changePctText = if (item.changePct >= 0) {
            String.format("+%.2f%%", item.changePct)
        } else {
            String.format("%.2f%%", item.changePct)
        }
        binding.tvChangePct.text = changePctText

        // 设置颜色
        val color = if (item.isUp) {
            ContextCompat.getColor(context, R.color.hq_rise_color)
        } else {
            ContextCompat.getColor(context, R.color.hq_fall_color)
        }
        binding.tvNetBuy.setTextColor(color)
        binding.tvChangePct.setTextColor(color)
    }
}
