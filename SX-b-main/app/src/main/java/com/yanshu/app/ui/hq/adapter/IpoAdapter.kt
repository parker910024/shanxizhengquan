package com.yanshu.app.ui.hq.adapter

import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.ViewGroup
import com.yanshu.app.databinding.ItemHqIpoBinding
import com.yanshu.app.ui.hq.model.IpoData
import ex.ss.lib.base.adapter.BaseItemAdapter

class IpoAdapter : BaseItemAdapter<IpoData, ItemHqIpoBinding>() {

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemHqIpoBinding {
        return ItemHqIpoBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemHqIpoBinding, position: Int) {
        val data = getItem(position)

        binding.tvIpoName.text = data.name
        binding.tvIpoCode.text = data.code
        binding.tvIssuePrice.text = "¥${String.format("%.2f", data.issuePrice)}"

        val zqRate = data.zqRate.toDoubleOrNull() ?: 0.0
        binding.tvZqRate.text = if (zqRate > 0) "${String.format("%.2f", zqRate)}%" else "0%"

        binding.tvFxNum.text = formatFxNum(data.fxNum)

        val (tagText, tagColor) = getMarketTagInfo(data.market)
        binding.tvMarketTag.text = tagText
        (binding.tvMarketTag.background as? GradientDrawable)?.setColor(tagColor)
    }

    private fun formatFxNum(raw: String): String {
        val v = raw.toLongOrNull() ?: return raw
        return when {
            v >= 100_000_000L -> String.format("%.1f亿股", v / 100_000_000.0)
            v >= 10_000L -> String.format("%.1f万股", v / 10_000.0)
            else -> "${v}股"
        }
    }

    private fun getMarketTagInfo(market: String): Pair<String, Int> {
        return when (market) {
            "京" -> "北" to 0xFF3B82F6.toInt()
            "北交" -> "北" to 0xFF3B82F6.toInt()
            "科" -> "科" to 0xFFF97316.toInt()
            "科创" -> "科" to 0xFFF97316.toInt()
            "沪" -> "沪" to 0xFFEF4444.toInt()
            "深" -> "深" to 0xFF3B82F6.toInt()
            "创" -> "创" to 0xFF10B981.toInt()
            else -> market.take(1) to 0xFF6B7280.toInt()
        }
    }
}
