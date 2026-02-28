package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.data.BlockTradeItem
import com.yanshu.app.databinding.ItemBlockTradeBinding

/**
 * 大宗交易（天启护盘）列表适配器
 */
class BlockTradeAdapter(
    private val onBuyClick: (BlockTradeItem) -> Unit
) : ListAdapter<BlockTradeItem, BlockTradeAdapter.VH>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemBlockTradeBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = getItem(position)
        holder.bind(item)
        holder.binding.tvAction.setOnClickListener { onBuyClick(item) }
    }

    class VH(val binding: ItemBlockTradeBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(item: BlockTradeItem) {
            binding.tvMarketTag.text = item.getMarketTag()
            binding.tvName.text = item.title
            binding.tvCode.text = item.code
            binding.tvPrice.text = "¥${item.cai_buy}"
            binding.tvTotal.text = item.max_num.toString()
        }
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<BlockTradeItem>() {
            override fun areItemsTheSame(a: BlockTradeItem, b: BlockTradeItem) = a.id == b.id
            override fun areContentsTheSame(a: BlockTradeItem, b: BlockTradeItem) = a == b
        }
    }
}
