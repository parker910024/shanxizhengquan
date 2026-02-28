package ex.ss.lib.components.loadmore

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asFlow
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

sealed class LoadMoreData<K, T> {
    class Result<K, T>(val list: List<T>, val nextKey: K? = null) : LoadMoreData<K, T>()
    class Error<K, T>(val list: List<T> = listOf()) : LoadMoreData<K, T>()

}

enum class LoadMoreStatus {
    NoLoading, Refresh, LoadMore, Error
}

data class LoadStatus<K>(val status: LoadMoreStatus, val key: K)
interface LoadMoreComponent<K, T> {
    fun init(pageSize: Int, initialKey: K)
    fun refresh()
    fun loadMore(): Boolean
    fun currentList(): List<T>
    fun observe(owner: LifecycleOwner, observer: (result: LoadMoreData.Result<K, T>) -> Unit)
    fun observeLoadStatus(owner: LifecycleOwner, observer: (status: LoadStatus<K>) -> Unit)
    fun flow(): Flow<LoadMoreData.Result<K, T>>
    fun loadStatusFlow(): Flow<LoadStatus<K>>
}

class LoadMoreConfig<K>(val pageSize: Int, val pageKey: K)

class ViewModelLoadMoreComponent<K, T>(
    loadMoreConfig: LoadMoreConfig<K>? = null,
    private val scope: CoroutineScope,
    private val loadMore: suspend (pageSize: Int, pageNum: K) -> LoadMoreData<K, T>,
) : LoadMoreComponent<K, T> {

    private val initialConfig = AtomicReference<LoadMoreConfig<K>>()
    private val currentPageSize = AtomicInteger(0)
    private val currentPageKey = AtomicReference<K>(null)

    private val currentCacheData = mutableListOf<T>()

    private val currentLoadMoreData = AtomicReference<LoadMoreData<K, T>>(null)

    private val isLoadingMore = AtomicBoolean(false)

    private val loadStatusLiveData = MutableLiveData<LoadStatus<K>>()
    private val loadDataLiveData = MutableLiveData<LoadMoreData.Result<K, T>>()

    init {
        loadMoreConfig?.also {
            initialConfig.set(it)
            currentPageSize.set(it.pageSize)
            currentPageKey.set(it.pageKey)
        }
    }

    private fun loadMoreData(isRefresh: Boolean, pageSize: Int, pageKey: K) = scope.launch {
        if (isLoadingMore.compareAndSet(false, true)) {
            val loadStatus = if (isRefresh) LoadMoreStatus.Refresh else LoadMoreStatus.LoadMore
            loadStatusLiveData.postValue(LoadStatus(loadStatus, pageKey))

            val loadData = loadMore.invoke(pageSize, pageKey)
            currentLoadMoreData.set(loadData)

            if (loadData is LoadMoreData.Result) {
                val dataList = mutableListOf<T>().apply { addAll(currentCacheData) }
                dataList.addAll(loadData.list)

                currentCacheData.addAll(loadData.list)

                loadDataLiveData.postValue(LoadMoreData.Result(dataList, loadData.nextKey))
                loadStatusLiveData.postValue(LoadStatus(LoadMoreStatus.NoLoading, pageKey))
            } else {
                val dataList = mutableListOf<T>().apply { addAll(currentCacheData) }

                loadDataLiveData.postValue(LoadMoreData.Result(dataList, null))
                loadStatusLiveData.postValue(LoadStatus(LoadMoreStatus.Error, pageKey))
            }
            isLoadingMore.set(false)
        }
    }

    override fun init(pageSize: Int, initialKey: K) {
        initialConfig.set(LoadMoreConfig(pageSize, initialKey))
        currentPageSize.set(pageSize)
        currentPageKey.set(initialKey)
        loadMoreData(false, currentPageSize.get(), currentPageKey.get())
    }

    override fun refresh() {
        val config = initialConfig.get() ?: throw RuntimeException("you must be call init method!")
        currentPageSize.set(config.pageSize)
        currentPageKey.set(config.pageKey)
        currentCacheData.clear()
        loadMoreData(true, currentPageSize.get(), currentPageKey.get())
    }

    override fun loadMore(): Boolean {
        val loadMoreData = currentLoadMoreData.get()
        return if (!isLoadingMore.get() && loadMoreData is LoadMoreData.Result && loadMoreData?.nextKey != null) {
            loadMoreData(false, currentPageSize.get(), loadMoreData.nextKey)
            true
        } else false
    }

    override fun flow(): Flow<LoadMoreData.Result<K, T>> {
        return loadDataLiveData.asFlow()
    }

    override fun loadStatusFlow(): Flow<LoadStatus<K>> {
        return loadStatusLiveData.asFlow()
    }

    override fun currentList(): List<T> = currentCacheData

    override fun observe(
        owner: LifecycleOwner,
        observer: (result: LoadMoreData.Result<K, T>) -> Unit,
    ) {
        loadDataLiveData.observe(owner, observer)
    }

    override fun observeLoadStatus(
        owner: LifecycleOwner,
        observer: (status: LoadStatus<K>) -> Unit,
    ) {
        loadStatusLiveData.observe(owner, observer)
    }
}

fun <K, T> ViewModel.loadMore(
    loadMoreConfig: LoadMoreConfig<K>,
    loadMore: suspend (pageSize: Int, pageKey: K) -> LoadMoreData<K, T>,
): LoadMoreComponent<K, T> {
    return ViewModelLoadMoreComponent(
        loadMoreConfig = loadMoreConfig,
        scope = viewModelScope,
        loadMore = loadMore
    )
}

fun <K, T> ViewModel.loadMore(loadMore: suspend (pageSize: Int, pageKey: K) -> LoadMoreData<K, T>): LoadMoreComponent<K, T> {
    return ViewModelLoadMoreComponent(scope = viewModelScope, loadMore = loadMore)
}