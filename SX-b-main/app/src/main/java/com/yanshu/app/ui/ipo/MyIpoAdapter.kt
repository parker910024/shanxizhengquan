package com.yanshu.app.ui.ipo

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.data.MyIpoItem
import com.yanshu.app.databinding.ItemMyIpoBinding

class MyIpoAdapter : ListAdapter<MyIpoItem, MyIpoAdapter.VH>(DIFF) {

    private var onRenjiaoClick: ((MyIpoItem) -> Unit)? = null

    fun setOnRenjiaoClickListener(listener: (MyIpoItem) -> Unit) {
        onRenjiaoClick = listener
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemMyIpoBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) = holder.bind(getItem(position))

    inner class VH(private val binding: ItemMyIpoBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(item: MyIpoItem) {
            binding.tvName.text = item.name
            binding.tvCode.text = item.code
            binding.tvStatus.text = item.status_txt.ifEmpty { getStatusText(item) }
            binding.tvPrice.text = String.format("%.2f", item.sg_fx_price)
            binding.tvQuantity.text = item.zq_num.toString()
            binding.tvDate.text = item.createtime_txt

            binding.tvListingDate.text = if (item.sg_ss_tag == 1 && item.sg_ss_date.isNotEmpty() && item.sg_ss_date != "0000-00-00") {
                item.sg_ss_date
            } else {
                "未公布"
            }

            // 使用 sy_renjiao 表示剩余认缴金额：>0 表示还有剩余，0 表示已全部认缴
            val remainAmount = item.sy_renjiao
            if (remainAmount > 0.0) {
                binding.tvPaidLabel.text = "剩余认缴"
                binding.tvPaidAmount.text = String.format("%.2f", remainAmount)
            } else {
                binding.tvPaidLabel.text = "已认缴"
                binding.tvPaidAmount.text = String.format("%.2f", item.zq_money)
            }

            // 中签且还有剩余认缴金额时才允许继续认缴
            if (item.status == "1" && remainAmount > 0.0) {
                binding.btnRenjiao.visibility = View.VISIBLE
                binding.btnRenjiao.setOnClickListener { onRenjiaoClick?.invoke(item) }
            } else {
                binding.btnRenjiao.visibility = View.GONE
            }
        }

        private fun getStatusText(item: MyIpoItem): String {
            return when (item.status) {
                "0" -> "申购中"
                "1" -> "中签${item.zq_nums}(手)"
                "2" -> "未中签"
                "3" -> "已弃购"
                else -> ""
            }
        }
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<MyIpoItem>() {
            override fun areItemsTheSame(a: MyIpoItem, b: MyIpoItem) = a.id == b.id
            override fun areContentsTheSame(a: MyIpoItem, b: MyIpoItem) = a == b
        }
    }
}
