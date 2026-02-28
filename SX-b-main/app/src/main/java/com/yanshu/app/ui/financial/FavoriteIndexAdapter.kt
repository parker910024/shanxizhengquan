package com.yanshu.app.ui.financial

import android.view.LayoutInflater
import android.view.ViewGroup
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemFavoriteIndexBinding
import com.yanshu.app.ui.hq.model.IndexData
import ex.ss.lib.base.adapter.BaseItemAdapter

class FavoriteIndexAdapter(
    private val onItemClick: ((IndexData) -> Unit)? = null,
) : BaseItemAdapter<IndexData, ItemFavoriteIndexBinding>() {

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemFavoriteIndexBinding {
        return ItemFavoriteIndexBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemFavoriteIndexBinding, position: Int) {
        val data = getItem(position)
        binding.root.setOnClickListener { onItemClick?.invoke(data) }
        val textColor = if (data.isUp) {
            getColor(R.color.hq_rise_color)
        } else {
            getColor(R.color.hq_fall_color)
        }

        binding.tvIndexName.text = data.name
        binding.tvIndexValue.text = String.format("%.2f", data.value)
        binding.tvIndexValue.setTextColor(textColor)

        val changeSign = if (data.change >= 0) "+" else ""
        binding.tvIndexChange.text = String.format("%s%.2f", changeSign, data.change)
        binding.tvIndexChange.setTextColor(textColor)
        
        binding.tvIndexPercent.text = String.format("%.2f%%", kotlin.math.abs(data.changePercent))
        binding.tvIndexPercent.setTextColor(textColor)
    }
}
