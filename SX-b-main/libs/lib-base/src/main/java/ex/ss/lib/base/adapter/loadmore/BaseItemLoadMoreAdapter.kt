package ex.ss.lib.base.adapter.loadmore

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.viewbinding.ViewBinding
import ex.ss.lib.base.adapter.OnMultiBindHolder
import ex.ss.lib.base.adapter.loadmore.data.LoadMoreItem
import ex.ss.lib.base.databinding.ItemBaseLoadMoreViewBinding
//extension
abstract class BaseItemLoadMoreAdapter<T : LoadMoreItem, VB : ViewBinding> :
    BaseMultiLoadMoreAdapter(), OnMultiBindHolder<T, VB> {

    init {
        register(itemDataClass(), object : OnMultiBindHolder<T, VB> {
            override fun onCreateViewBinding(inflater: LayoutInflater, parent: ViewGroup): VB {
                return this@BaseItemLoadMoreAdapter.onCreateViewBinding(inflater, parent)
            }

            override fun onBind(binding: VB, data: T, position: Int) {
                return this@BaseItemLoadMoreAdapter.onBind(binding, data, position)
            }

            override fun onBindPayload(
                binding: VB, data: T, position: Int, payloads: MutableList<Any>,
            ): Boolean {
                return this@BaseItemLoadMoreAdapter.onBindPayload(binding, data, position, payloads)
            }
        })
    }

    override fun loadMoreViewBinding(inflater: LayoutInflater, parent: ViewGroup): ViewBinding {
        return ItemBaseLoadMoreViewBinding.inflate(inflater, parent, false)
    }

    abstract fun itemDataClass(): Class<T>

}