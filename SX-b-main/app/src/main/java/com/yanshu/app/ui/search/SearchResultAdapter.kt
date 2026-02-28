package com.yanshu.app.ui.search

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.databinding.ItemStockSearchResultBinding

class SearchResultAdapter(
    private val onItemClick: (StockSearchResult) -> Unit
) : ListAdapter<StockSearchResult, SearchResultAdapter.ViewHolder>(DiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemStockSearchResultBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class ViewHolder(
        private val binding: ItemStockSearchResultBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(stock: StockSearchResult) {
            binding.tvStockName.text = stock.name
            binding.tvStockCode.text = stock.code
            binding.tvStockLatter.text = stock.latter

            binding.root.setOnClickListener {
                onItemClick(stock)
            }
        }
    }

    class DiffCallback : DiffUtil.ItemCallback<StockSearchResult>() {
        override fun areItemsTheSame(oldItem: StockSearchResult, newItem: StockSearchResult): Boolean {
            return oldItem.displayCode == newItem.displayCode
        }

        override fun areContentsTheSame(oldItem: StockSearchResult, newItem: StockSearchResult): Boolean {
            return oldItem == newItem
        }
    }
}

/**
 * 鑲＄エ鎼滅储缁撴灉鏁版嵁
 */
data class StockSearchResult(
    val name: String,
    val code: String,
    val displayCode: String, // 鏄剧ず鐢ㄧ殑浠ｇ爜锛屽 "娣?000001"
    val latter: String,      // 绠€鎷?
    val price: Double,
)
