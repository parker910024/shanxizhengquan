package com.yanshu.app.ui.search

import android.content.Context
import android.content.Intent
import android.view.View
import android.view.inputmethod.EditorInfo
import androidx.core.widget.addTextChangedListener
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.StockSearchApiItem
import com.yanshu.app.databinding.ActivityStockSearchBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.deal.BuyActivity
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.hq.detail.StockDetailActivity
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class StockSearchActivity : BasicActivity<ActivityStockSearchBinding>() {

    companion object {
        private const val EXTRA_BUY_MODE = "extra_buy_mode"
        private const val PAGE_SIZE = 20
        private const val LOAD_MORE_THRESHOLD = 5

        fun start(context: Context) {
            context.startActivity(Intent(context, StockSearchActivity::class.java))
        }

        fun startForBuy(context: Context) {
            context.startActivity(
                Intent(context, StockSearchActivity::class.java)
                    .putExtra(EXTRA_BUY_MODE, true)
            )
        }
    }

    override val binding: ActivityStockSearchBinding by viewBinding()

    private var buyMode = false

    private lateinit var hotStockAdapter: HotStockAdapter
    private lateinit var searchResultAdapter: SearchResultAdapter
    private var searchJob: Job? = null

    private var searchRequestToken = 0L
    private var activeKeyword: String = ""
    private var currentPage = 0
    private var hasMore = true
    private var isSearching = false
    private val currentResults = mutableListOf<StockSearchResult>()

    override fun initView() {
        buyMode = intent.getBooleanExtra(EXTRA_BUY_MODE, false)
        setupTitleBar()
        setupSearchBox()
        setupHotStockList()
        setupSearchResultList()
    }

    override fun initData() {
        loadHotStocks()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.stock_search_title)
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun setupSearchBox() {
        binding.tvSearch.setOnClickListener { performSearch() }

        binding.etSearch.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                performSearch()
                true
            } else {
                false
            }
        }

        binding.etSearch.addTextChangedListener { text ->
            if (text.isNullOrBlank()) {
                searchJob?.cancel()
                clearSearchState()
                showHotSearch()
            } else {
                searchJob?.cancel()
                searchJob = lifecycleScope.launch {
                    delay(300)
                    performSearch()
                }
            }
        }
    }

    private fun setupHotStockList() {
        hotStockAdapter = HotStockAdapter { stock ->
            openStockDetailFromHot(stock)
        }

        binding.rvHotStocks.apply {
            layoutManager = GridLayoutManager(this@StockSearchActivity, 3)
            adapter = hotStockAdapter
        }
    }

    private fun setupSearchResultList() {
        searchResultAdapter = SearchResultAdapter { stock ->
            openStockDetail(stock)
        }
        val linearLayoutManager = LinearLayoutManager(this@StockSearchActivity)

        binding.rvSearchResults.apply {
            layoutManager = linearLayoutManager
            adapter = searchResultAdapter
            addOnScrollListener(object : RecyclerView.OnScrollListener() {
                override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                    if (dy <= 0) return
                    if (activeKeyword.isBlank() || !hasMore || isSearching) return
                    val totalCount = linearLayoutManager.itemCount
                    if (totalCount <= 0) return
                    val lastVisible = linearLayoutManager.findLastVisibleItemPosition()
                    if (lastVisible >= totalCount - LOAD_MORE_THRESHOLD) {
                        loadMore()
                    }
                }
            })
        }
    }

    private fun loadHotStocks() {
        // 鐑悳鑲＄エ锛氬畬鍏ㄤ娇鐢ㄦ湰鍦板啓姝荤殑鏁版嵁锛屼笉鍐嶄緷璧栦笢鏂硅储瀵屾帴鍙?
        hotStockAdapter.submitList(buildHotStocks())
        showHotSearch()
    }

    private fun buildHotStocks(): List<HotStock> = listOf(
        HotStock(1, "平安银行", "sz000001"),
        HotStock(2, "贵州茅台", "sh600519"),
        HotStock(3, "东方财富", "sz300059"),
        HotStock(4, "比亚迪", "sz002594"),
        HotStock(5, "宁德时代", "sz300750"),
        HotStock(6, "中芯国际", "sh688981"),
    )

    private fun performSearch() {
        val keyword = binding.etSearch.text?.toString()?.trim().orEmpty()
        if (keyword.isEmpty()) {
            clearSearchState()
            showHotSearch()
            return
        }
        searchJob?.cancel()
        startSearch(keyword = keyword, reset = true)
    }

    private fun loadMore() {
        if (activeKeyword.isBlank() || !hasMore || isSearching) return
        startSearch(keyword = activeKeyword, reset = false)
    }

    private fun startSearch(keyword: String, reset: Boolean) {
        if (isSearching && !reset) return

        if (reset) {
            activeKeyword = keyword
            currentPage = 0
            hasMore = true
            currentResults.clear()
        }

        val requestPage = if (reset) 1 else currentPage + 1
        val token = ++searchRequestToken
        isSearching = true

        lifecycleScope.launch {
            try {
                val response = Remote.callApi {
                    searchStockByKey(keyword = keyword, page = requestPage, size = PAGE_SIZE)
                }
                if (token != searchRequestToken) return@launch

                if (!response.isSuccess()) {
                    if (reset) showHotSearch()
                    return@launch
                }

                val apiItems = response.data.list
                if (reset && apiItems.isEmpty()) {
                    showHotSearch()
                    AppToast.show("鏈壘鍒板尮閰嶇殑鑲＄エ")
                    return@launch
                }

                hasMore = apiItems.size >= PAGE_SIZE
                currentPage = requestPage

                val pageResults = buildSearchResults(apiItems)
                if (reset) {
                    currentResults.clear()
                    currentResults.addAll(pageResults)
                } else {
                    appendUniqueResults(pageResults)
                }

                if (currentResults.isEmpty()) {
                    showHotSearch()
                } else {
                    showSearchResults(currentResults.toList())
                }
            } finally {
                if (token == searchRequestToken) {
                    isSearching = false
                }
            }
        }
    }

    private suspend fun buildSearchResults(apiItems: List<StockSearchApiItem>): List<StockSearchResult> {
        if (apiItems.isEmpty()) return emptyList()

        return apiItems.map { item ->
            val backendPrice = item.cai_buy.toPriceDouble()

            StockSearchResult(
                name = item.name,
                code = item.code,
                displayCode = item.allcode,
                latter = item.latter,
                price = backendPrice,
            )
        }
    }

    private fun appendUniqueResults(newItems: List<StockSearchResult>) {
        if (newItems.isEmpty()) return
        val existing = currentResults.map { it.displayCode.lowercase() }.toHashSet()
        val appendItems = newItems.filter { existing.add(it.displayCode.lowercase()) }
        currentResults.addAll(appendItems)
    }

    private fun clearSearchState() {
        // Invalidate in-flight responses when user clears keyword.
        searchRequestToken++
        activeKeyword = ""
        currentPage = 0
        hasMore = true
        isSearching = false
        currentResults.clear()
        searchResultAdapter.submitList(emptyList())
    }

    private fun String.toPriceDouble(): Double {
        return replace(",", "").trim().toDoubleOrNull() ?: 0.0
    }

    private fun showHotSearch() {
        binding.tvHotTitle.visibility = View.VISIBLE
        binding.rvHotStocks.visibility = View.VISIBLE

        binding.tvListTitle.visibility = View.GONE
        binding.layoutTableHeader.visibility = View.GONE
        binding.rvSearchResults.visibility = View.GONE
    }

    private fun showSearchResults(results: List<StockSearchResult>) {
        binding.tvHotTitle.visibility = View.GONE
        binding.rvHotStocks.visibility = View.GONE

        binding.tvListTitle.visibility = View.VISIBLE
        binding.layoutTableHeader.visibility = View.VISIBLE
        binding.rvSearchResults.visibility = View.VISIBLE

        searchResultAdapter.submitList(results)
    }

    private fun openStockDetailFromHot(stock: HotStock) {
        if (buyMode) {
            BuyActivity.startForBuy(this, allcode = stock.code, name = stock.name)
            return
        }
        val lowerCode = stock.code.lowercase()
        val marketHint = when {
            lowerCode.startsWith("sh") -> "sh"
            lowerCode.startsWith("sz") -> "sz"
            lowerCode.startsWith("bj") -> "bj"
            else -> "sz"
        }
        val code = stock.code.removePrefix("sh").removePrefix("sz")
            .removePrefix("bj").removePrefix("SH").removePrefix("SZ").removePrefix("BJ")
        StockDetailActivity.start(
            context = this,
            code = code,
            name = stock.name,
            marketHint = marketHint,
            isIndex = false,
        )
    }

    private fun openStockDetail(stock: StockSearchResult) {
        if (buyMode) {
            BuyActivity.startForBuy(this, allcode = stock.displayCode, name = stock.name, price = stock.price)
            return
        }
        StockDetailActivity.start(
            context = this,
            code = stock.code,
            name = stock.name,
            marketHint = inferMarketHint(stock),
            isIndex = isIndexCode(stock),
        )
    }

    private fun inferMarketHint(stock: StockSearchResult): String {
        val display = stock.displayCode.lowercase().replace(" ", "")
        return when {
            display.startsWith("sh") -> "sh"
            display.startsWith("sz") -> "sz"
            display.startsWith("bj") -> "bj"
            isBeiJingCode(stock.code) -> "bj"
            stock.code.startsWith("6") -> "sh"
            stock.code.startsWith("5") -> "sh"
            stock.code.startsWith("9") -> "sh"
            else -> "sz"
        }
    }

    private fun isBeiJingCode(code: String): Boolean {
        val normalized = code.filter { it.isDigit() }
        return normalized.startsWith("4")
            || normalized.startsWith("8")
            || normalized.startsWith("92")
            || normalized.startsWith("83")
            || normalized.startsWith("87")
            || normalized.startsWith("43")
    }

    private fun isIndexCode(stock: StockSearchResult): Boolean {
        val code = stock.code
        val display = stock.displayCode.lowercase()
        return code.startsWith("399")
            || code.startsWith("899")
            || code == "000016"
            || code == "000300"
            || code == "000688"
            || code == "000852"
            || code == "000905"
            || (code == "000001" && display.startsWith("sh"))
    }
}

data class HotStock(
    val rank: Int,
    val name: String,
    val code: String,
)
