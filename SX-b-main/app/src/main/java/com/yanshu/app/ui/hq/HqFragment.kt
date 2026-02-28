package com.yanshu.app.ui.hq

import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import com.yanshu.app.R
import com.yanshu.app.databinding.FragmentHqBinding
import com.yanshu.app.model.IPOViewModel
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dialog.BulkTradeBuyDialog
import com.yanshu.app.ui.hq.adapter.BlockTradeAdapter
import com.yanshu.app.ui.hq.adapter.IndexAdapter
import com.yanshu.app.ui.hq.adapter.IpoAdapter
import com.yanshu.app.ui.hq.adapter.PlacementAdapter
import com.yanshu.app.ui.hq.adapter.GridSpacingItemDecoration
import com.yanshu.app.ui.hq.adapter.SectorAdapter
import com.yanshu.app.ui.hq.adapter.StockAdapter
import com.yanshu.app.ui.hq.detail.StockDetailActivity
import com.yanshu.app.ui.hq.model.FundFlowInfo
import com.yanshu.app.ui.hq.model.IndexData
import com.yanshu.app.ui.hq.model.StockData
import com.yanshu.app.ui.placement.PlacementDetailActivity
import com.yanshu.app.util.TabIndicatorHelper
import ex.ss.lib.base.extension.viewBinding
import ex.ss.lib.base.fragment.BaseFragment
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class HqFragment : BaseFragment<FragmentHqBinding>() {

    override val binding: FragmentHqBinding by viewBinding()

    private val viewModel: HqViewModel by lazy {
        ViewModelProvider(this)[HqViewModel::class.java]
    }

    private lateinit var indexAdapter: IndexAdapter
    private lateinit var industrySectorAdapter: SectorAdapter
    private lateinit var conceptSectorAdapter: SectorAdapter
    private lateinit var stockAdapter: StockAdapter
    private lateinit var ipoAdapter: IpoAdapter
    private lateinit var placementAdapter: PlacementAdapter
    private lateinit var blockTradeAdapter: BlockTradeAdapter

    private var placementLoaded = false
    private var blockTradeLoaded = false

    private val handler = Handler(Looper.getMainLooper())
    private var fundInfoIndex = 0
    private val fundInfoList = mutableListOf<FundFlowInfo>()

    private lateinit var topTabs: List<TextView>
    private var selectedTopTabIndex = 0

    private lateinit var rankingTabs: List<TextView>
    private var selectedRankingTabIndex = 0
    private lateinit var rankingTabIndicatorHelper: TabIndicatorHelper

    // Tab 瀵瑰簲鐨勫垪瀹藉害 (dp): 鐜颁环80, 娑ㄨ穼70, 娑ㄨ穼骞?0, 鎴愪氦棰?00, 鎹㈡墜鐜?0, 鏄ㄦ敹80, 浠婂紑80, 鏈€楂?0
    private val columnWidths = listOf(80, 70, 70, 100, 70, 80, 80, 80)
    private val columnPositions: List<Int> by lazy {
        var sum = 0
        columnWidths.map { width ->
            val pos = sum
            sum += width
            pos
        }
    }

    override fun initialize() {
        initTopTabs()
        initAdapters()
        initRankingTabs()
    }

    override fun initView() {
        setupRecyclerViews()
        setupFundInfoScroll()
        setupScrollSync()
        setupLoadMore()
        observeViewModel()
    }

    override fun initData() {
        android.util.Log.d("sp_ts", "HqFragment initData -> viewModel.loadAll()")
        loadHqConfigNames()
        viewModel.loadAll()
    }

    private fun loadHqConfigNames() {
        viewLifecycleOwner.lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val config = response.data ?: return@launch
            val dzName = config.dz_syname.trim()
            if (dzName.isNotEmpty()) {
                binding.tvTabProtection.text = dzName
            }
            val strategyName = config.is_xxps_name.trim()
            if (strategyName.isNotEmpty()) {
                binding.tvTabStrategy.text = strategyName
            }
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 椤堕儴 Tab 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun initTopTabs() {
        topTabs = listOf(
            binding.tvTabMarket,
            binding.tvTabIpo,
            binding.tvTabStrategy,
            binding.tvTabProtection,
        )
        topTabs.forEachIndexed { index, textView ->
            textView.setOnClickListener { updateTopTabSelection(index) }
        }
        updateTopTabSelection(0)
    }

    private fun updateTopTabSelection(index: Int) {
        selectedTopTabIndex = index

        topTabs.forEachIndexed { i, textView ->
            val isSelected = i == index
            textView.animate()
                .scaleX(if (isSelected && i == 0) 1.0f else if (isSelected) 1.1f else 1.0f)
                .scaleY(if (isSelected && i == 0) 1.0f else if (isSelected) 1.1f else 1.0f)
                .setDuration(200)
                .start()

            if (i == 0) {
                textView.textSize = if (isSelected) 24f else 18f
                textView.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
                textView.setTextColor(
                    ContextCompat.getColor(
                        requireContext(),
                        if (isSelected) R.color.hq_title_color else R.color.hq_subtitle_color,
                    ),
                )
            } else {
                textView.textSize = if (isSelected) 18f else 16f
                textView.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
                textView.setTextColor(
                    ContextCompat.getColor(
                        requireContext(),
                        if (isSelected) R.color.hq_title_color else R.color.hq_subtitle_color,
                    ),
                )
            }
        }

        binding.layoutMarketContent.visibility = View.GONE
        binding.layoutIpoContent.visibility = View.GONE
        binding.layoutStrategyContent.visibility = View.GONE
        binding.layoutProtectionContent.visibility = View.GONE

        when (index) {
            0 -> binding.layoutMarketContent.visibility = View.VISIBLE
            1 -> {
                binding.layoutIpoContent.visibility = View.VISIBLE
                updateIpoDate()
            }
            2 -> {
                binding.layoutStrategyContent.visibility = View.VISIBLE
                if (!placementLoaded) {
                    placementLoaded = true
                    IPOViewModel.loadPlacementList()
                }
            }
            3 -> {
                binding.layoutProtectionContent.visibility = View.VISIBLE
                if (!blockTradeLoaded) {
                    blockTradeLoaded = true
                    IPOViewModel.loadBlockTradeList()
                }
            }
        }
    }

    private fun updateIpoDate() {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd E", Locale.CHINESE)
        binding.tvIpoDate.text = dateFormat.format(Date())
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 鑲＄エ鎺掕姒?Tab 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun initRankingTabs() {
        rankingTabs = listOf(
            binding.tvRankPrice,
            binding.tvRankChange,
            binding.tvRankChangePct,
            binding.tvRankVolume,
            binding.tvRankTurnover,
            binding.tvRankPrevClose,
            binding.tvRankOpen,
            binding.tvRankHigh,
        )
        rankingTabIndicatorHelper = TabIndicatorHelper.createWithFixedWidths(
            tabs = rankingTabs.map { it as View },
            indicator = binding.viewRankingIndicator,
            columnWidthsDp = columnWidths,
            indicatorWidthDp = 24,
        )
        rankingTabs.forEachIndexed { index, textView ->
            textView.setOnClickListener {
                updateRankingTabSelection(index)
                scrollStockListToColumn(index)
            }
        }
        rankingTabIndicatorHelper.init(0)
        updateRankingTabStyles(0)
    }

    private fun updateRankingTabSelection(index: Int) {
        selectedRankingTabIndex = index
        updateRankingTabStyles(index)
        rankingTabIndicatorHelper.selectTab(index)
    }

    private fun updateRankingTabStyles(index: Int) {
        rankingTabs.forEachIndexed { i, textView ->
            val isSelected = i == index
            textView.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
            textView.setTextColor(
                ContextCompat.getColor(
                    requireContext(),
                    if (isSelected) R.color.hq_title_color else R.color.hq_text_gray,
                ),
            )
        }
    }

    private fun scrollStockListToColumn(columnIndex: Int) {
        val density = resources.displayMetrics.density
        val scrollX = (columnPositions.getOrElse(columnIndex) { 0 } * density).toInt()
        binding.hsvRankingTabs.smoothScrollTo(scrollX, 0)
        binding.layoutStockHeader.hsvHeader.smoothScrollTo(scrollX, 0)
        stockAdapter.scrollToColumn(columnIndex)
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ Adapter 鍒濆鍖?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun initAdapters() {
        indexAdapter = IndexAdapter { item -> openIndexDetail(item) }
        industrySectorAdapter = SectorAdapter()
        conceptSectorAdapter = SectorAdapter()
        stockAdapter = StockAdapter(
            onScrollChange = { scrollX ->
                binding.layoutStockHeader.hsvHeader.scrollTo(scrollX, 0)
            },
            onItemClick = { item -> openStockDetail(item) },
        )
        ipoAdapter = IpoAdapter()
        placementAdapter = PlacementAdapter { item ->
            PlacementDetailActivity.start(requireContext(), item)
        }
        blockTradeAdapter = BlockTradeAdapter { item ->
            BulkTradeBuyDialog.show(
                childFragmentManager, item,
                IPOViewModel.blockTradeBalanceLiveData.value ?: 0.0,
            )
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ ViewModel 鏁版嵁瑙傚療 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun observeViewModel() {
        // 鎸囨暟蹇収
        viewModel.indexList.observe(viewLifecycleOwner) { list ->
            val sparklines = viewModel.indexSparklines.value ?: emptyMap()
            indexAdapter.submitList(list.map { index ->
                index.copy(sparklinePrices = sparklines[index.code] ?: emptyList())
            })
        }

        // 鎸囨暟璧板娍鍥撅紙鍗曠嫭鏇存柊锛岄伩鍏嶅啀娆℃媺蹇収锛?
        viewModel.indexSparklines.observe(viewLifecycleOwner) { sparklines ->
            val currentList = viewModel.indexList.value ?: return@observe
            indexAdapter.submitList(currentList.map { index ->
                index.copy(sparklinePrices = sparklines[index.code] ?: emptyList())
            })
        }

        // 鑲＄エ鎺掕姒?
        viewModel.stockList.observe(viewLifecycleOwner) { list ->
            stockAdapter.submitList(list)
        }

        viewModel.stockLoadState.observe(viewLifecycleOwner) { state ->
            when (state) {
                0 -> {
                    binding.layoutLoadMore.visibility = View.GONE
                    binding.pbLoading.visibility = View.GONE
                    binding.tvNoMore.visibility = View.GONE
                }
                1 -> {
                    binding.layoutLoadMore.visibility = View.VISIBLE
                    binding.pbLoading.visibility = View.VISIBLE
                    binding.tvNoMore.visibility = View.GONE
                }
                2 -> {
                    binding.layoutLoadMore.visibility = View.VISIBLE
                    binding.pbLoading.visibility = View.GONE
                    binding.tvNoMore.visibility = View.VISIBLE
                }
            }
        }

        // 鏂拌偂鐢宠喘鍒楄〃
        viewModel.ipoList.observe(viewLifecycleOwner) { list ->
            ipoAdapter.submitList(list)
        }

        // 琛屼笟鏉垮潡
        viewModel.industrySectors.observe(viewLifecycleOwner) { list ->
            industrySectorAdapter.submitList(list)
        }

        // 姒傚康鏉垮潡
        viewModel.conceptSectors.observe(viewLifecycleOwner) { list ->
            conceptSectorAdapter.submitList(list)
        }

        // 涨跌家数：驱动进度条
        viewModel.riseCount.observe(viewLifecycleOwner) { (rise, fall, _) ->
            updateMarketOverviewBar(rise, fall)
        }

        // 涨跌分布：驱动柱状图
        viewModel.marketDistribution.observe(viewLifecycleOwner) { data ->
            binding.viewMarketDistribution.setData(data)
        }

        // 璧勯噾娴佸悜
        viewModel.fundFlow.observe(viewLifecycleOwner) { list ->
            if (list.isNotEmpty()) {
                fundInfoList.clear()
                fundInfoList.addAll(list)
                // 绔嬪嵆鏄剧ず绗竴鏉?
                showFundInfo(fundInfoList[0])
            }
        }

        // 绾夸笅閰嶅敭鍒楄〃
        IPOViewModel.placementListLiveData.observe(viewLifecycleOwner) { list ->
            placementAdapter.submitList(list)
            binding.tvStrategyEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
            binding.rvPlacement.visibility = if (list.isEmpty()) View.GONE else View.VISIBLE
        }

        // 澶у畻浜ゆ槗鍒楄〃
        IPOViewModel.blockTradeListLiveData.observe(viewLifecycleOwner) { list ->
            blockTradeAdapter.submitList(list)
            binding.tvProtectionEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
            binding.rvBlockTrade.visibility = if (list.isEmpty()) View.GONE else View.VISIBLE
        }

        // 鎿嶄綔缁撴灉
        IPOViewModel.operationResult.observe(viewLifecycleOwner) { result ->
            result ?: return@observe
            val (action, success, _) = result
            if (action == "buyBlockTrade") {
                if (success) {
                    AppToast.show("成功")
                    IPOViewModel.loadBlockTradeList()
                }
            }
            IPOViewModel.clearOperationResult()
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ RecyclerView 璁剧疆 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun setupRecyclerViews() {
        binding.rvIndex.apply {
            layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
            adapter = indexAdapter
        }
        val sectorSpacing = resources.getDimensionPixelSize(R.dimen.sector_grid_spacing)
        val sectorDecoration = GridSpacingItemDecoration(3, sectorSpacing, includeEdge = true)
        binding.rvIndustrySector.apply {
            addItemDecoration(sectorDecoration)
            adapter = industrySectorAdapter
        }
        binding.rvConceptSector.apply {
            addItemDecoration(GridSpacingItemDecoration(3, sectorSpacing, includeEdge = true))
            adapter = conceptSectorAdapter
        }
        binding.rvStock.adapter = stockAdapter
        binding.rvPlacement.layoutManager = LinearLayoutManager(context)
        binding.rvPlacement.adapter = placementAdapter
        binding.rvBlockTrade.layoutManager = LinearLayoutManager(context)
        binding.rvBlockTrade.adapter = blockTradeAdapter
        binding.rvIpo.adapter = ipoAdapter
        ipoAdapter.setOnItemClick { data, _ ->
            IpoDetailActivity.start(
                requireContext(),
                name = data.name,
                code = data.code,
                market = data.market,
                issuePrice = data.issuePrice,
                peRatio = data.peRatio,
                board = data.board,
                fxNum = data.fxNum,
                wsfxNum = data.wsfxNum,
                sgLimit = data.sgLimit,
                sgDate = data.sgDate,
                ssDate = data.ssDate,
                zqRate = data.zqRate,
                industry = data.industry,
            )
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 璧勯噾娴佸悜婊氬姩鍔ㄧ敾 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun setupFundInfoScroll() {
        startFundInfoScrollAnimation()
    }

    private fun showFundInfo(info: FundFlowInfo) {
        if (!isAdded) return
        binding.tvFundLabel.text = info.label
        binding.tvFundValue.text = info.value
        binding.tvFundValue.setTextColor(
            ContextCompat.getColor(
                requireContext(),
                if (info.isPositive) R.color.hq_rise_color else R.color.hq_fall_color,
            ),
        )
    }

    private fun startFundInfoScrollAnimation() {
        val scrollRunnable = object : Runnable {
            override fun run() {
                if (!isAdded || fundInfoList.isEmpty()) {
                    handler.postDelayed(this, 5000)
                    return
                }
                binding.layoutFundInfo.animate()
                    .translationY(-binding.layoutFundInfo.height.toFloat())
                    .setDuration(300)
                    .withEndAction {
                        if (!isAdded) return@withEndAction
                        fundInfoIndex = (fundInfoIndex + 1) % fundInfoList.size
                        showFundInfo(fundInfoList[fundInfoIndex])
                        binding.layoutFundInfo.translationY = binding.layoutFundInfo.height.toFloat()
                        binding.layoutFundInfo.animate()
                            .translationY(0f)
                            .setDuration(300)
                            .start()
                    }
                    .start()
                handler.postDelayed(this, 5000)
            }
        }
        handler.postDelayed(scrollRunnable, 5000)
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 娑ㄨ穼杩涘害鏉?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun updateMarketOverviewBar(rise: Int, fall: Int) {
        binding.tvTotalRise.text = "上涨${rise}"
        binding.tvTotalFall.text = "下跌${fall}"

        val total = (rise + fall).toFloat()
        if (total > 0) {
            val riseWeight = rise / total * 100
            val fallWeight = fall / total * 100

            val riseParams = binding.viewRiseBar.layoutParams as LinearLayout.LayoutParams
            riseParams.weight = riseWeight
            binding.viewRiseBar.layoutParams = riseParams

            val fallParams = binding.viewFallBar.layoutParams as LinearLayout.LayoutParams
            fallParams.weight = fallWeight
            binding.viewFallBar.layoutParams = fallParams
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 妯悜婊氬姩鍚屾 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun setupScrollSync() {
        binding.hsvRankingTabs.setOnScrollChangeListener { _, scrollX, _, _, _ ->
            binding.layoutStockHeader.hsvHeader.scrollTo(scrollX, 0)
            stockAdapter.syncAllScrollViews(scrollX)
        }
        binding.layoutStockHeader.hsvHeader.setOnScrollChangeListener { _, scrollX, _, _, _ ->
            binding.hsvRankingTabs.scrollTo(scrollX, 0)
            stockAdapter.syncAllScrollViews(scrollX)
        }
    }

    private fun setupLoadMore() {
        binding.nestedScroll.setOnScrollChangeListener(
            androidx.core.widget.NestedScrollView.OnScrollChangeListener { v, _, scrollY, _, _ ->
                if (selectedTopTabIndex != 0) return@OnScrollChangeListener
                val child = v.getChildAt(0) ?: return@OnScrollChangeListener
                val distanceToBottom = child.height - v.height - scrollY
                if (distanceToBottom < 300) {
                    viewModel.loadMoreStocks()
                }
            },
        )
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 瀵艰埅 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    private fun openStockDetail(item: StockData) {
        StockDetailActivity.start(
            context = requireContext(),
            code = item.code,
            name = item.name,
            marketHint = item.market,
            isIndex = false,
        )
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

    private fun inferIndexCode(name: String): String {
        return when {
            name.contains("上证") -> "000001"
            name.contains("深证") -> "399001"
            name.contains("创业") -> "399006"
            name.contains("科创") -> "000688"
            name.contains("沪深300") || name.contains("CSI 300", ignoreCase = true) -> "000300"
            else -> ""
        }
    }

    // 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ 鐢熷懡鍛ㄦ湡 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

    override fun onResume() {
        super.onResume()
        checkPendingSubTab()
    }

    private fun checkPendingSubTab() {
        val pendingIndex = com.yanshu.app.ui.main.MainActivity.pendingHqSubTab
        if (pendingIndex >= 0 && pendingIndex < topTabs.size) {
            selectTopTab(pendingIndex)
            com.yanshu.app.ui.main.MainActivity.pendingHqSubTab = -1
        }
    }

    /**
     * 閫夋嫨椤堕儴 Tab
     * @param index Tab绱㈠紩: 0=琛屾儏, 1=鏂拌偂鐢宠喘, 2=鎴樼暐閰嶅敭, 3=澶╁惎鎶ょ洏
     */
    fun selectTopTab(index: Int) {
        if (index in topTabs.indices) {
            updateTopTabSelection(index)
        }
    }

    override fun onDestroyView() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroyView()
    }
}
