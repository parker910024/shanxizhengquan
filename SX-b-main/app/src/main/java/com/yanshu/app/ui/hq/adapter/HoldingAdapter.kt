package com.yanshu.app.ui.hq.adapter

import android.view.LayoutInflater
import android.view.View
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
            binding.tvMarket.text = marketLabel(item.type)
            binding.tvCode.text = item.code
            binding.tvTime.text = if (isHistory) {
                val sellTime = item.outtime_name.ifBlank { item.createtime_name }
                "卖出时间：$sellTime"
            } else {
                item.createtime_name
            }
            binding.tvPrincipal.text = formatFixed2(item.cityValueDouble())
            binding.tvNumber.text = item.number
            binding.tvBuyPrice.text = formatFixed2(item.buyprice)
            binding.tvCurrentPrice.text = formatFixed2(item.caiBuyDouble())
            binding.tvPriceLabel.text = if (isHistory) "卖出价" else "当前价"

            val profitVal = item.profitLoseDouble()
            val profitColor = if (profitVal >= 0) R.color.hq_rise_color else R.color.hq_fall_color
            val color = ContextCompat.getColor(binding.root.context, profitColor)
            binding.tvProfit.text = "%.2f".format(profitVal)
            binding.tvProfit.setTextColor(color)
            if (isHistory) {
                binding.tvProfitRate.visibility = View.GONE
            } else {
                binding.tvProfitRate.visibility = View.VISIBLE
                binding.tvProfitRate.text = item.profitLose_rate
                binding.tvProfitRate.setTextColor(color)
            }

            binding.btnSell.visibility = if (isHistory) View.GONE else View.VISIBLE
            binding.btnSell.setOnClickListener {
                onSellClick?.invoke(item)
            }
        }

        private fun marketLabel(type: Int): String = when (type) {
            1 -> "沪"
            2 -> "深"
            3 -> "创"
            4 -> "京"
            5 -> "科"
            6 -> "基"
            else -> ""
        }

        /** 金额/价格/数量统一保留两位小数 */
        private fun formatFixed2(value: Double): String = "%.2f".format(value)
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<HoldingItem>() {
            override fun areItemsTheSame(a: HoldingItem, b: HoldingItem) = a.id == b.id
            override fun areContentsTheSame(a: HoldingItem, b: HoldingItem) = a == b
        }
    }
}
