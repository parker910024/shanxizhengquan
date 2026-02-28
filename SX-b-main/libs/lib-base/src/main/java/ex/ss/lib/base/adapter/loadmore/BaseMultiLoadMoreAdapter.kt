package ex.ss.lib.base.adapter.loadmore

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.viewbinding.ViewBinding
import ex.ss.lib.base.adapter.BaseMultiAdapter
import ex.ss.lib.base.adapter.OnMultiBindHolder
import ex.ss.lib.base.adapter.data.BaseMultiItem
import ex.ss.lib.base.adapter.loadmore.data.LoadMoreViewData


abstract class BaseMultiLoadMoreAdapter : BaseMultiAdapter() {
    init {
        register(
            LoadMoreViewData::class.java,
            object : OnMultiBindHolder<LoadMoreViewData, ViewBinding> {
                override fun onCreateViewBinding(
                    inflater: LayoutInflater, parent: ViewGroup,
                ): ViewBinding {
                    return loadMoreViewBinding(inflater, parent)
                }

                override fun onBind(binding: ViewBinding, data: LoadMoreViewData, position: Int) {

                }

            })
    }

    fun submitList(
        list: MutableList<BaseMultiItem>, showLoadMore: Boolean, commitCallback: Runnable?,
    ) {
        if (showLoadMore) {
            list.add(LoadMoreViewData())
        } else {
            //防御性处理
            list.removeAll { it is LoadMoreViewData }
        }
        super.submitList(list, commitCallback)
    }

    abstract fun loadMoreViewBinding(inflater: LayoutInflater, parent: ViewGroup): ViewBinding

}

