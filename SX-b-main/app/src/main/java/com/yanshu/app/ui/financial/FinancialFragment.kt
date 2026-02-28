package com.yanshu.app.ui.financial

import android.content.Intent
import android.view.View
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.StockListItem
import com.yanshu.app.databinding.FragmentFinancialBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.hq.detail.StockDetailActivity
import com.yanshu.app.ui.hq.model.FavoriteData
import com.yanshu.app.ui.hq.model.IndexData
import com.yanshu.app.ui.main.MainActivity
import com.yanshu.app.ui.search.StockSearchActivity
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import ex.ss.lib.base.fragment.BaseFragment
import kotlinx.coroutines.launch

class FinancialFragment : BaseFragment<FragmentFinancialBinding>() {

    override val binding: FragmentFinancialBinding by viewBinding()

    private lateinit var indexAdapter: FavoriteIndexAdapter
    private lateinit var favoriteAdapter: FavoriteAdapter

    override fun initialize() {
    }

    override fun initView() {
        setupTitleBar()
        setupIndexRecyclerView()
        setupFavoriteRecyclerView()
        setupEmptyState()
    }

    private fun setupTitleBar() {
        binding.ivService.setOnClickListener {
            CustomerServiceNavigator.open(requireActivity(), viewLifecycleOwner.lifecycleScope)
        }
        binding.ivSearch.setOnClickListener {
            startActivity(Intent(requireContext(), StockSearchActivity::class.java))
        }
    }

    override fun initData() {
        android.util.Log.d("sp_ts", "FinancialFragment initData")
        loadIndexData()
        if (UserConfig.isLogin()) loadFavoriteData()
    }

    private fun setupIndexRecyclerView() {
        indexAdapter = FavoriteIndexAdapter { item -> openIndexDetail(item) }
        binding.rvIndex.layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
        binding.rvIndex.adapter = indexAdapter
    }

    private fun openIndexDetail(item: IndexData) {
        val code = item.code.ifBlank { inferIndexCode(item.name) }
        if (code.isBlank()) {
            AppToast.show("暂无该指数行情数据")
            return
        }
        StockDetailActivity.start(
            context = requireContext(),
            code = code,
            name = item.name,
            marketHint = item.marketHint,
            isIndex = true,
        )
    }

    private fun inferIndexCode(name: String): String = when {
        name.contains("上证") -> "000001"
        name.contains("深证") -> "399001"
        name.contains("创业") -> "399006"
        name.contains("科创") -> "000688"
        name.contains("沪深300") || name.contains("CSI 300", ignoreCase = true) -> "000300"
        else -> ""
    }

    private fun setupFavoriteRecyclerView() {
        favoriteAdapter = FavoriteAdapter()
        binding.rvFavorite.layoutManager = LinearLayoutManager(requireContext())
        binding.rvFavorite.adapter = favoriteAdapter
        // 关闭列表项变更动画，避免每次进入页面 submitList 时整表闪一下
        binding.rvFavorite.itemAnimator = null
        favoriteAdapter.onItemClick = { item ->
            StockDetailActivity.start(
                requireContext(),
                code = item.code,
                name = item.name,
                marketHint = item.market,
                isIndex = item.isIndex,
            )
        }
    }

    private fun setupEmptyState() {
        binding.ivAddFavorite.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(0)
        }
        binding.layoutEmpty.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(0)
        }
    }

    private fun loadIndexData() {
        viewLifecycleOwner.lifecycleScope.launch {
            val result = runCatching { Remote.callApi { getIndexMarket() } }.getOrNull()
            val items = result?.data?.list?.mapNotNull { item ->
                val arr = item.allcodes_arr
                if (arr.size < 6) return@mapNotNull null
                val price = arr.getOrNull(3)?.toDoubleOrNull() ?: return@mapNotNull null
                val change = arr.getOrNull(4)?.toDoubleOrNull() ?: 0.0
                val changePct = arr.getOrNull(5)?.toDoubleOrNull() ?: 0.0
                val marketHint = when {
                    item.allcode.startsWith("sh", ignoreCase = true) -> "sh"
                    item.allcode.startsWith("bj", ignoreCase = true) -> "bj"
                    else -> "sz"
                }
                IndexData(
                    name = item.title,
                    value = price,
                    change = change,
                    changePercent = changePct,
                    isUp = change >= 0,
                    code = item.code,
                    marketHint = marketHint,
                )
            }.orEmpty().take(5)
            if (!items.isNullOrEmpty()) {
                indexAdapter.submitList(items)
            }
        }
    }

    private fun loadFavoriteData() {
        if (!UserConfig.isLogin()) return
        android.util.Log.d("sp_ts", "FinancialFragment loadFavoriteData -> getZixuanNew()")
        viewLifecycleOwner.lifecycleScope.launch {
            val response = Remote.callApi { getZixuanNew(page = 1, size = 50) }
            val list = response.data?.list.orEmpty().map { it.toFavoriteData() }
            if (list.isEmpty()) {
                showEmptyState()
            } else {
                showDataState(list)
            }
        }
    }

    private fun showEmptyState() {
        binding.layoutEmpty.visibility = View.VISIBLE
        binding.rvFavorite.visibility = View.GONE
    }

    private fun showDataState(data: List<FavoriteData>) {
        // 先提交数据，在 ListAdapter 完成 diff 并提交后再切换显示列表，避免进入页面时列表先露空再刷新导致的闪烁
        favoriteAdapter.submitList(data) {
            if (binding.layoutEmpty.visibility == View.VISIBLE) {
                binding.layoutEmpty.visibility = View.GONE
                binding.rvFavorite.visibility = View.VISIBLE
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // 返回到理财页时重新拉取一次自选列表，保证“加入/取消自选”后数据刷新
        if (UserConfig.isLogin()) {
            loadFavoriteData()
        } else {
            showEmptyState()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
    }

    private fun StockListItem.toFavoriteData(): FavoriteData {
        val market = when {
            symbol.startsWith("sh") -> "沪"
            symbol.startsWith("sz") -> "深"
            symbol.startsWith("bj") -> "北"
            symbol.startsWith("kc") -> "科"
            else -> ""
        }
        val price = trade.toDoubleOrNull() ?: 0.0
        val changePercent = changepercent.toDoubleOrNull() ?: 0.0
        val changeAmount = pricechange.toDoubleOrNull() ?: 0.0
        return FavoriteData(
            name = name,
            code = code,
            market = market,
            price = price,
            changePercent = changePercent,
            changeAmount = changeAmount,
            isUp = changePercent >= 0,
            isIndex = isIndexFavoriteSymbol(symbol, code),
        )
    }

    private fun isIndexFavoriteSymbol(symbol: String, code: String): Boolean {
        val normalizedCode = code.filter { it.isDigit() }
        if (normalizedCode.isBlank()) return false

        val lowerSymbol = symbol.lowercase()

        if (lowerSymbol.startsWith("sh000")) return true
        if (lowerSymbol.startsWith("sz399")) return true
        if (lowerSymbol.startsWith("bj899")) return true

        return normalizedCode.startsWith("399")
            || normalizedCode.startsWith("899")
            || (normalizedCode.startsWith("000") && lowerSymbol.startsWith("sh"))
    }
}
