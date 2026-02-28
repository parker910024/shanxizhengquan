package com.yanshu.app.ui.search

import android.graphics.Color
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.databinding.ItemStockSearchHotBinding

class HotStockAdapter(
    private val onItemClick: (HotStock) -> Unit
) : ListAdapter<HotStock, HotStockAdapter.ViewHolder>(DiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemStockSearchHotBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class ViewHolder(
        private val binding: ItemStockSearchHotBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(stock: HotStock) {
            binding.tvStockName.text = stock.name
            binding.tvStockCode.text = stock.code
            binding.tvRank.text = stock.rank.toString()

            // 根据排名设置角标颜色
            val rankColor = when (stock.rank) {
                1 -> Color.parseColor("#FCB355") // 橙色
                2 -> Color.parseColor("#FF6E42") // 红色
                3 -> Color.parseColor("#F9C030") // 黄色
                else -> Color.parseColor("#BCBCBC") // 灰色
            }
            binding.viewRankBg.setBackgroundColor(rankColor)

            binding.root.setOnClickListener {
                onItemClick(stock)
            }
        }
    }

    class DiffCallback : DiffUtil.ItemCallback<HotStock>() {
        override fun areItemsTheSame(oldItem: HotStock, newItem: HotStock): Boolean {
            return oldItem.rank == newItem.rank && oldItem.code == newItem.code
        }

        override fun areContentsTheSame(oldItem: HotStock, newItem: HotStock): Boolean {
            return oldItem == newItem
        }
    }
}
