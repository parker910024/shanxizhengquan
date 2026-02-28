package com.yanshu.app.ui.placement

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.data.MyPlacementItem
import com.yanshu.app.databinding.ItemMyPlacementBinding

class MyPlacementAdapter : ListAdapter<MyPlacementItem, MyPlacementAdapter.VH>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemMyPlacementBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) = holder.bind(getItem(position))

    class VH(private val binding: ItemMyPlacementBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(item: MyPlacementItem) {
            binding.tvName.text = item.name
            binding.tvCode.text = item.code
            binding.tvStatus.text = item.status_txt
            binding.tvPrice.text = String.format("%.2f", item.sg_fx_price)
            binding.tvQuantity.text = item.zq_num.toString()
            binding.tvDate.text = item.createtime_txt
        }
    }

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<MyPlacementItem>() {
            override fun areItemsTheSame(a: MyPlacementItem, b: MyPlacementItem) = a.id == b.id
            override fun areContentsTheSame(a: MyPlacementItem, b: MyPlacementItem) = a == b
        }
    }
}
