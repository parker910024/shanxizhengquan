package ex.ss.lib.base.adapter

import android.content.Context
import android.graphics.drawable.Drawable
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import androidx.viewbinding.ViewBinding

class BaseViewHolder<VB : ViewBinding>(val binding: VB) : RecyclerView.ViewHolder(binding.root)

typealias OnAdapterItemClick<T> = (data: T, pos: Int) -> Unit

abstract class BaseAdapter<T, VB : ViewBinding>(diffCallback: DiffUtil.ItemCallback<T>) :
    ListAdapter<T, BaseViewHolder<VB>>(diffCallback) {

    protected lateinit var context: Context

    private var onItemClickListener: OnAdapterItemClick<T>? = null

    fun setOnItemClick(listener: OnAdapterItemClick<T>) {
        this.onItemClickListener = listener
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BaseViewHolder<VB> {
        context = parent.context
        val layoutInflater = LayoutInflater.from(context)
        val binding = viewBinding(layoutInflater, parent)
        return BaseViewHolder(binding)
    }

    override fun onBindViewHolder(
        holder: BaseViewHolder<VB>, position: Int, payloads: MutableList<Any>
    ) {
        holder.binding.root.setOnClickListener {
            callItemClick(getItem(position), position)
        }
        if (payloads.isEmpty() || !onBindViewHolder(holder.binding, position, payloads)) {
            onBindViewHolder(holder, position)
        }
    }

    fun callItemClick(data: T, position: Int) {
        onItemClickListener?.invoke(data, position)
    }

    override fun onBindViewHolder(holder: BaseViewHolder<VB>, position: Int) {
        onBindViewHolder(holder.binding, position)
    }

    abstract fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): VB

    abstract fun onBindViewHolder(binding: VB, position: Int)

    open fun onBindViewHolder(binding: VB, position: Int, payloads: MutableList<Any>): Boolean {
        return false
    }

    fun getColor(res: Int): Int {
        return ContextCompat.getColor(context, res)
    }

    fun getDrawable(res: Int): Drawable? {
        return ContextCompat.getDrawable(context, res)
    }

    fun getString(res: Int, vararg formatArgs: Any): String {
        return context.resources.getString(res, *formatArgs)
    }
}
