package ex.ss.lib.base.adapter

import androidx.recyclerview.widget.DiffUtil
import androidx.viewbinding.ViewBinding
import ex.ss.lib.base.adapter.data.BaseItem

abstract class BaseItemAdapter<T : BaseItem, VB : ViewBinding> :
    BaseAdapter<T, VB>(object : DiffUtil.ItemCallback<T>() {
        override fun areItemsTheSame(oldItem: T, newItem: T): Boolean {
            return oldItem == newItem
        }

        override fun areContentsTheSame(oldItem: T, newItem: T): Boolean {
            return oldItem.areContentsTheSame(newItem)
        }
    })