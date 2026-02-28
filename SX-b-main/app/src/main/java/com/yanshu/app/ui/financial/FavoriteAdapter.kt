package com.yanshu.app.ui.financial

import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.ViewGroup
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemFavoriteBinding
import com.yanshu.app.ui.hq.model.FavoriteData
import ex.ss.lib.base.adapter.BaseItemAdapter

class FavoriteAdapter : BaseItemAdapter<FavoriteData, ItemFavoriteBinding>() {

    var onItemClick: ((FavoriteData) -> Unit)? = null

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemFavoriteBinding {
        return ItemFavoriteBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemFavoriteBinding, position: Int) {
        val data = getItem(position)
        binding.root.setOnClickListener { onItemClick?.invoke(data) }
        
        // 名称和代码
        binding.tvName.text = data.name
        binding.tvCode.text = data.code
        binding.tvMarket.text = data.market
        
        // 设置市场标签背景颜色
        val marketColor = when (data.market) {
            "沪" -> getColor(R.color.hq_rise_color)
            "深" -> getColor(android.R.color.holo_blue_dark)
            "北" -> getColor(android.R.color.holo_blue_light)
            else -> getColor(R.color.hq_text_gray)
        }
        (binding.tvMarket.background as? GradientDrawable)?.setColor(marketColor)
        
        // 最新价格
        binding.tvPrice.text = String.format("%.2f", data.price)
        
        // 涨跌颜色
        val changeColor = if (data.isUp) {
            getColor(R.color.hq_rise_color)
        } else {
            getColor(R.color.hq_fall_color)
        }
        
        // 涨跌幅
        val sign = if (data.changePercent >= 0) "+" else ""
        binding.tvChangePercent.text = String.format("%s%.2f%%", sign, data.changePercent)
        binding.tvChangePercent.setTextColor(changeColor)
        
        // 涨跌额
        binding.tvChangeAmount.text = String.format("%.2f", data.changeAmount)
        binding.tvChangeAmount.setTextColor(changeColor)
    }
}
