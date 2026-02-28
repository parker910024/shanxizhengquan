package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import com.yanshu.app.R
import com.yanshu.app.databinding.ItemHqSectorBinding
import com.yanshu.app.ui.hq.model.SectorData
import ex.ss.lib.base.adapter.BaseItemAdapter

class SectorAdapter : BaseItemAdapter<SectorData, ItemHqSectorBinding>() {

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemHqSectorBinding {
        return ItemHqSectorBinding.inflate(inflater, parent, false)
    }

    override fun onBindViewHolder(binding: ItemHqSectorBinding, position: Int) {
        val data = getItem(position)
        val textColor = if (data.isUp) {
            getColor(R.color.hq_rise_color)
        } else {
            getColor(R.color.hq_fall_color)
        }

        binding.tvSectorName.text = data.name
        
        val changeSign = if (data.changePercent >= 0) "+" else ""
        binding.tvSectorChange.text = String.format("%s%.2f%%", changeSign, data.changePercent)
        binding.tvSectorChange.setTextColor(textColor)

        val topStockSign = if (data.topStockChange >= 0) "+" else ""
        val topStockColor = if (data.topStockChange >= 0) {
            getColor(R.color.hq_rise_color)
        } else {
            getColor(R.color.hq_fall_color)
        }
        binding.tvTopStock.text = String.format(
            "%s  %s%.2f%%",
            data.topStock, topStockSign, data.topStockChange
        )
        binding.tvTopStock.setTextColor(topStockColor)
    }
}
