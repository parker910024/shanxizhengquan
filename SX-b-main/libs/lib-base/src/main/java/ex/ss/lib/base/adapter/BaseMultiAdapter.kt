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
import ex.ss.lib.base.adapter.data.BaseMultiItem

class BaseMultiAdapterViewHolder<VB : ViewBinding>(internal val binding: VB) :
    RecyclerView.ViewHolder(binding.root)

val diffBaseMultiItem = object : DiffUtil.ItemCallback<BaseMultiItem>() {
    override fun areItemsTheSame(oldItem: BaseMultiItem, newItem: BaseMultiItem): Boolean {
        return oldItem == newItem
    }

    override fun areContentsTheSame(oldItem: BaseMultiItem, newItem: BaseMultiItem): Boolean {
        return oldItem.areContentsTheSame(newItem)
    }
}

interface OnMultiBindHolder<T : BaseMultiItem, VB : ViewBinding> {

    fun onCreateViewBinding(inflater: LayoutInflater, parent: ViewGroup): VB

    fun onBind(binding: VB, data: T, position: Int)

    fun onBindPayload(binding: VB, data: T, position: Int, payloads: MutableList<Any>): Boolean {
        return false
    }
}

typealias OnMultiAdapterItemClick = (item: BaseMultiItem, position: Int) -> Unit


abstract class BaseMultiAdapter :
    ListAdapter<BaseMultiItem, BaseMultiAdapterViewHolder<ViewBinding>>(diffBaseMultiItem) {

    protected lateinit var context: Context

    private val bindMapper = mutableMapOf<Int, OnMultiBindHolder<BaseMultiItem, ViewBinding>>()
    private val viewTypeMapper = mutableMapOf<Class<*>, Int>()

    private var onItemClick: OnMultiAdapterItemClick? = null

    @Suppress("UNCHECKED_CAST")
    fun <T : BaseMultiItem, VB : ViewBinding> register(
        clazz: Class<T>, bind: OnMultiBindHolder<T, VB>
    ) {
        val typeIndex = viewTypeMapper.size
        viewTypeMapper[clazz] = typeIndex
        bindMapper[typeIndex] = bind as OnMultiBindHolder<BaseMultiItem, ViewBinding>
    }

    fun setOnItemClick(onItemClick: OnMultiAdapterItemClick) {
        this.onItemClick = onItemClick
    }

    override fun getItemViewType(position: Int): Int {
        val item = getItem(position)
        return viewTypeMapper.firstNotNullOfOrNull { if (it.key == item::class.java) it.value else null }
            ?: -1
    }

    override fun onCreateViewHolder(
        parent: ViewGroup, viewType: Int
    ): BaseMultiAdapterViewHolder<ViewBinding> {
        context = parent.context
        val bind = bindMapper[viewType]
            ?: throw IllegalArgumentException("not fount $viewType")
        val inflater = LayoutInflater.from(parent.context)
        return BaseMultiAdapterViewHolder(bind.onCreateViewBinding(inflater, parent))
    }

    override fun onBindViewHolder(
        holder: BaseMultiAdapterViewHolder<ViewBinding>, position: Int, payloads: MutableList<Any>
    ) {
        if (payloads.isNotEmpty()) {
            val viewType = getItemViewType(position)
            val bind = bindMapper[viewType]
                ?: throw IllegalArgumentException("not fount $viewType")
            val item = getItem(position)
            if (bind.onBindPayload(holder.binding, item, position, payloads)) {
                return
            }
        }
        onBindViewHolder(holder, position)
    }

    override fun onBindViewHolder(holder: BaseMultiAdapterViewHolder<ViewBinding>, position: Int) {
        val viewType = getItemViewType(position)
        val bind = bindMapper[viewType]
            ?: throw IllegalArgumentException("not fount $viewType")
        val item = getItem(position)
        holder.binding.root.setOnClickListener {
            onItemClick?.invoke(item, position)
        }
        bind.onBind(holder.binding, item, position)
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