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

        // 净买入：与 iOS 一致的格式（亿 / 万 / 元）
        val amt = item.netBuy
        val absAmt = kotlin.math.abs(amt)
        val sign = if (amt < 0) "-" else ""
        val netBuyText = when {
            absAmt >= 100_000_000 -> String.format("%s%.2f亿", sign, absAmt / 100_000_000)
            absAmt >= 10_000 -> String.format("%s%.2f万", sign, absAmt / 10_000)
            else -> String.format("%s%.0f", sign, absAmt)
        }
        binding.tvNetBuy.text = netBuyText

        // 涨跌幅
        val changePctText = if (item.changePct >= 0) {
            String.format("+%.2f%%", item.changePct)
        } else {
            String.format("%.2f%%", item.changePct)
        }
        binding.tvChangePct.text = changePctText

        // 净买入与涨跌幅独立着色：净买入看资金方向，涨跌幅看价格方向
        val riseColor = ContextCompat.getColor(context, R.color.hq_rise_color)
        val fallColor = ContextCompat.getColor(context, R.color.hq_fall_color)
        val neutralColor = ContextCompat.getColor(context, R.color.hq_stock_name_color)

        binding.tvNetBuy.setTextColor(
            when {
                item.netBuy > 0 -> riseColor
                item.netBuy < 0 -> fallColor
                else -> neutralColor
            }
        )
        binding.tvChangePct.setTextColor(
            when {
                item.changePct > 0 -> riseColor
                item.changePct < 0 -> fallColor
                else -> neutralColor
            }
        )
    }
}
