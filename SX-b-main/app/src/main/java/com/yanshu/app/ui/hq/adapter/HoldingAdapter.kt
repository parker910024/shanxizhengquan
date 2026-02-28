package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.databinding.ItemHoldingBinding

/**
 * 持仓列表适配器，当前持仓和历史持仓复用
 * @param isHistory true=历史持仓（显示卖出价），false=当前持仓（显示当前价）
 * @param onSellClick 卖出回调（仅当前持仓时有效）
 */
class HoldingAdapter(
    private val isHistory: Boolean = false,
    val onSellClick: ((HoldingItem) -> Unit)? = null,
    private val onItemClick: ((HoldingItem) -> Unit)? = null,
) : ListAdapter<HoldingItem, HoldingAdapter.VH>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemHoldingBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = getItem(position)
        holder.bind(item, isHistory, onSellClick)
        holder.itemView.setOnClickListener { onItemClick?.invoke(item) }
    }

    class VH(private val binding: ItemHoldingBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(item: HoldingItem, isHistory: Boolean, onSellClick: ((HoldingItem) -> Unit)?) {
            binding.tvName.text = item.title
            binding.tvCode.text = item.code
            binding.tvBuyPrice.text = "%.2f".format(item.buyprice)
            binding.tvCurrentPrice.text = "%.2f".format(item.cai_buy)
            binding.tvNumber.text = item.number
            binding.tvTime.text = item.createtime_name
            binding.tvPriceLabel.text = if (isHistory) "卖出价" else "当前价"

            val profitColor = if (item.profitLose >= 0) R.color.hq_rise_color else R.color.hq_fall_color
            val color = ContextCompat.getColor(binding.root.context, profitColor)
            binding.tvProfit.text = "%.2f".format(item.profitLose)
            binding.tvProfit.setTextColor(color)
            binding.tvProfitRate.text = item.profitLose_rate
            binding.tvProfitRate.setTextColor(color)
        }
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<HoldingItem>() {
            override fun areItemsTheSame(a: HoldingItem, b: HoldingItem) = a.id == b.id
            override fun areContentsTheSame(a: HoldingItem, b: HoldingItem) = a == b
        }
    }
}
