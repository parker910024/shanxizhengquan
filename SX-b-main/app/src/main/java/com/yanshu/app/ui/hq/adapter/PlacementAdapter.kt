package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.data.IPOItem
import com.yanshu.app.databinding.ItemPlacementBinding

/**
 * 线下配售（战略配售）列表适配器
 */
class PlacementAdapter(
    private val onItemClick: (IPOItem) -> Unit
) : ListAdapter<IPOItem, PlacementAdapter.VH>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemPlacementBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = getItem(position)
        holder.bind(item)
        holder.itemView.setOnClickListener { onItemClick(item) }
        holder.binding.tvAction.setOnClickListener { onItemClick(item) }
    }

    class VH(val binding: ItemPlacementBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(item: IPOItem) {
            binding.tvMarketTag.text = item.getMarketTag()
            binding.tvName.text = item.name
            binding.tvCode.text = item.code
            binding.tvPrice.text = "¥${item.fx_price}"
            val total = (item.fx_num.toDoubleOrNull() ?: 0.0) / 10000
            binding.tvTotal.text = String.format("%.1f万股", total)
        }
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<IPOItem>() {
            override fun areItemsTheSame(a: IPOItem, b: IPOItem) = a.id == b.id
            override fun areContentsTheSame(a: IPOItem, b: IPOItem) = a == b
        }
    }
}
