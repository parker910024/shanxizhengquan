package com.yanshu.app.ui.home

import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.databinding.FragmentHomeBinding
import com.yanshu.app.databinding.ItemHomeNewsBinding
import com.yanshu.app.config.NewsCache
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.ApiNewsItem
import com.yanshu.app.data.BannerItem
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dragon.DragonActivity
import com.yanshu.app.ui.home.NewsDetailActivity
import com.yanshu.app.ui.main.MainActivity
import com.yanshu.app.ui.message.MessageListActivity
import com.yanshu.app.ui.position.PositionRecordActivity
import com.yanshu.app.ui.ai.AiInvestActivity
import com.yanshu.app.ui.search.StockSearchActivity
import com.yanshu.app.ui.transfer.TransferInActivity
import com.yanshu.app.ui.transfer.TransferOutActivity
import com.yanshu.app.util.BrowserUtils
import com.yanshu.app.util.CustomerServiceNavigator
import com.yanshu.app.util.ImageUrlUtils
import com.yanshu.app.util.TabIndicatorHelper
import com.youth.banner.indicator.CircleIndicator
import android.util.Log
import androidx.core.graphics.toColorInt
import com.yanshu.app.repo.eastmoney.EastMoneyMarketRepository
import com.yanshu.app.data.MyIpoItem
import com.yanshu.app.ui.dialog.IpoReminderDialog
import com.yanshu.app.ui.dialog.WinningLotDialog
import com.yanshu.app.ui.ipo.MyIpoActivity
import ex.ss.lib.base.extension.viewBinding
import ex.ss.lib.base.fragment.BaseFragment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class HomeFragment : BaseFragment<FragmentHomeBinding>() {

    override val binding: FragmentHomeBinding by viewBinding()

    private var currentTabIndex = 0
    private val tabViews = mutableListOf<TextView>()
    private lateinit var tabIndicatorHelper: TabIndicatorHelper
    /** 当前 Tab 已加载的新闻列表，用于直击热点卡片点击 */
    private var currentNewsList: List<NewsItem> = emptyList()
    private var ipoReminderShown = false
    private var winningDialogShown = false
    
    override fun initialize() {
    }

    override fun initView() {
        setupClickListeners()
        setupTopBanner()
        setupNewsTabs()
        setupNewsRecyclerView()
    }
    
    private fun setupClickListeners() {
        // Top bar icons
        binding.ivService.setOnClickListener {
            val act = activity ?: return@setOnClickListener
            CustomerServiceNavigator.open(act, viewLifecycleOwner.lifecycleScope)
        }
        binding.llSearch.setOnClickListener { 
            startActivity(Intent(requireContext(), StockSearchActivity::class.java))
        }
        binding.ivMessage.setOnClickListener {
            startActivity(Intent(requireContext(), MessageListActivity::class.java))
        }
        
        // Quick functions row 1
        binding.llOpenAccount.setOnClickListener {
            com.yanshu.app.ui.realname.RealNameActivity.start(requireContext())
        }
        binding.llMarket.setOnClickListener { 
            (activity as? MainActivity)?.navigateToHq(0) // 0 = 行情
        }
        binding.llPosition.setOnClickListener { 
            PositionRecordActivity.start(requireContext())
        }
        binding.llTransferIn.setOnClickListener { TransferInActivity.start(requireContext()) }
        binding.llTransferOut.setOnClickListener { TransferOutActivity.start(requireContext()) }
        
        // Quick functions row 2
        binding.llNewStock.setOnClickListener { 
            com.yanshu.app.ui.ipo.NewStockSubscriptionActivity.start(requireContext())
        }
        binding.llOtc.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(3)
        }
        binding.llStrategy.setOnClickListener { 
            (activity as? MainActivity)?.navigateToHq(2) // 2 = 战略配售
        }
        binding.llAi.setOnClickListener { AiInvestActivity.start(requireContext()) }
        binding.llDragon.setOnClickListener { 
            startActivity(Intent(requireContext(), DragonActivity::class.java))
        }
        
        // Cards：直击热点点击进入当前 Tab 第一条新闻详情
        binding.cardHotNews.setOnClickListener {
            if (currentNewsList.isNotEmpty()) {
                NewsDetailActivity.start(requireContext(), currentNewsList[0].id)
            } else {
                showToast("直击热点")
            }
        }
        binding.cardRiseFall.setOnClickListener { showToast("涨平跌分布") }
        binding.cardTodayMarket.setOnClickListener { showToast("今日大盘") }
    }
    
    private fun setupNewsTabs() {
        // Initialize tab views list
        tabViews.clear()
        tabViews.add(binding.tabDynamic)
        tabViews.add(binding.tab7x24)
        tabViews.add(binding.tabMarketNews)
        tabViews.add(binding.tabAdvisor)
        tabViews.add(binding.tabImportant)
        
        // Initialize tab indicator helper
        tabIndicatorHelper = TabIndicatorHelper.create(
            tabs = tabViews.map { it as View },
            indicator = binding.tabIndicator,
            indicatorWidthDp = 24
        )
        
        // Set click listeners for tabs
        binding.tabDynamic.setOnClickListener { selectTab(0) }
        binding.tab7x24.setOnClickListener { selectTab(1) }
        binding.tabMarketNews.setOnClickListener { selectTab(2) }
        binding.tabAdvisor.setOnClickListener { selectTab(3) }
        binding.tabImportant.setOnClickListener { selectTab(4) }
        
        // Initialize indicator position after layout
        tabIndicatorHelper.init(0)
        
        // Select first tab by default (without animation for initial state)
        selectTab(0, animate = false)
    }
    
    private fun selectTab(index: Int, animate: Boolean = true) {
        currentTabIndex = index
        updateTabStyles(index)
        tabIndicatorHelper.selectTab(index, animate)
        loadNewsForTab(index)
    }

    /** 接口 type：1国内经济 2国际经济 3证券要闻 4公司咨询；与 Tab 对应 */
    private fun getTypeForTab(tabIndex: Int): Int = when (tabIndex) {
        0 -> 1   // 动态 -> 国内经济
        1 -> 2   // 7X24 -> 国际经济
        2 -> 3   // 盘面 -> 证券要闻
        3 -> 3   // 投顾 -> 证券要闻
        4 -> 4   // 要闻 -> 公司咨询
        else -> 1
    }

    private fun loadNewsForTab(tabIndex: Int) {
        val type = getTypeForTab(tabIndex)
        val cached = NewsCache.getNews(type)
        val list = cached.mapIndexed { i, api ->
            NewsItem(
                rank = if (i < 4) i + 1 else 0,
                title = api.news_title,
                time = api.news_time_text.ifEmpty { api.news_time },
                id = api.news_id
            )
        }
        currentNewsList = list
        if (list.isNotEmpty()) {
            binding.tvHotTitle.text = list[0].title
            binding.tvHotTime.text = list[0].time
        } else {
            binding.tvHotTitle.text = getString(R.string.home_hot_news)
            binding.tvHotTime.text = ""
        }
        val showRankIcon = (tabIndex == 0)
        binding.rvNews.adapter = NewsAdapter(list, showRankIcon) { news ->
            NewsDetailActivity.start(requireContext(), news.id)
        }
    }
    
    private fun updateTabStyles(selectedIndex: Int) {
        tabViews.forEachIndexed { i, textView ->
            val isSelected = i == selectedIndex
            // 选中: 黑色加粗, 未选中: 灰色正常
            textView.setTextColor(
                ContextCompat.getColor(
                    requireContext(),
                    if (isSelected) R.color.black else R.color.text_second_color
                )
            )
            textView.setTypeface(null, if (isSelected) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL)
            // 第一个Tab稍大
            textView.textSize = if (i == 0) 16f else 14f
        }
    }
    
    private fun setupNewsRecyclerView() {
        binding.rvNews.layoutManager = LinearLayoutManager(requireContext())
        // Initial adapter will be set by selectTab()
    }

    private fun setupTopBanner() {
        binding.topBanner.apply {
            indicator = CircleIndicator(requireContext())
            setIndicatorSelectedColorRes(R.color.banner_indicator_selected)
            setIndicatorNormalColorRes(R.color.banner_indicator_normal)
            setBannerRound(0f)
        }
    }

    private fun loadBanners() {
        if (!UserConfig.isLogin()) return
        android.util.Log.d("sp_ts", "HomeFragment loadBanners -> getBanners()")
        viewLifecycleOwner.lifecycleScope.launch {
            val stsResp = ContractRemote.callApiSilent { getAlicloudSTS() }
            val imageEndpoint = stsResp
                .takeIf { it.isSuccess() }
                ?.data
                ?.endpoint
                ?.trim()
                .orEmpty()
            if (imageEndpoint.startsWith("http://") || imageEndpoint.startsWith("https://")) {
                ImageUrlUtils.updateImageBaseUrl(imageEndpoint)
                Log.d(TAG_BANNER, "loadBanners: image endpoint updated=$imageEndpoint")
            } else {
                Log.w(TAG_BANNER, "loadBanners: image endpoint empty, fallback to BuildConfig")
            }

            val response = ContractRemote.callApiSilent { getBanners() }
            val list = when {
                !response.isSuccess() -> emptyList()
                else -> response.data.list.orEmpty()
            }
            Log.d(TAG_BANNER, "loadBanners: success=${response.isSuccess()}, list.size=${list.size}")
            withContext(Dispatchers.Main.immediate) {
                if (!isAdded || view == null) return@withContext
                if (list.isNotEmpty()) {
                    binding.topBannerPlaceholder.visibility = View.GONE
                    binding.topBanner.visibility = View.VISIBLE
                    binding.topBanner.setAdapter(
                        HomeBannerAdapter(list) { item -> handleBannerClick(item) }
                    )
                    binding.topBanner.start()
                } else {
                    binding.topBannerPlaceholder.visibility = View.VISIBLE
                    binding.topBanner.visibility = View.GONE
                }
            }
        }
    }

    private val emMarketRepo by lazy { EastMoneyMarketRepository() }

    private fun loadMarketData() {
        android.util.Log.d("sp_ts", "HomeFragment loadMarketData -> getIndexMarket()+EastMoney")
        viewLifecycleOwner.lifecycleScope.launch {
            try {
                val fundFlowDeferred = async {
                    runCatching { emMarketRepo.fetchFundFlow() }.getOrDefault(emptyList())
                }
                val riseFallDeferred = async {
                    runCatching { emMarketRepo.fetchCombinedRiseFall() }.getOrNull()
                }
                val mainFundDeferred = async {
                    runCatching { emMarketRepo.fetchMainFundFlow() }.getOrNull()
                }
                val indexDeferred = async {
                    runCatching { Remote.callApi { getIndexMarket() } }.getOrNull()
                }

                val fundFlows = fundFlowDeferred.await()
                val riseFall = riseFallDeferred.await()
                val mainFund = mainFundDeferred.await()
                val indexData = indexDeferred.await()

                // 北向/南向资金净流入
                val redColor = "#E05A55".toColorInt()
                val greenColor = "#4A8A43".toColorInt()
                fundFlows.firstOrNull { it.label == "北向资金净流入" }?.let { info ->
                    binding.tvNorthFund.text = info.value
                    binding.tvNorthFund.setTextColor(if (info.isPositive) redColor else greenColor)
                }
                fundFlows.firstOrNull { it.label == "南向资金净流入" }?.let { info ->
                    binding.tvSouthFund.text = info.value
                    binding.tvSouthFund.setTextColor(if (info.isPositive) redColor else greenColor)
                }

                // A股主力净流入
                mainFund?.let { info ->
                    binding.tvMainFund.text = info.value
                    binding.tvMainFund.setTextColor(if (info.isPositive) redColor else greenColor)
                }

                // 涨平跌家数
                riseFall?.let { (rise, fall, flat) ->
                    binding.tvRiseCount.text = rise.toString()
                    binding.tvFlatCount.text = flat.toString()
                    binding.tvFallCount.text = fall.toString()
                }

                // 今日大盘（取第一条指数）
                val firstIndex = indexData?.data?.list?.firstOrNull()?.allcodes_arr
                if (firstIndex != null && firstIndex.size >= 6) {
                    val name = firstIndex.getOrNull(1) ?: ""
                    val price = firstIndex.getOrNull(3) ?: ""
                    val change = firstIndex.getOrNull(4) ?: ""
                    val pct = firstIndex.getOrNull(5) ?: ""
                    val isDown = change.startsWith("-")
                    binding.tvMarketChange.text = "$change $pct%"
                    binding.tvMarketChange.setTextColor(if (isDown) greenColor else redColor)
                    binding.tvMarketIndex.text = "$name $price"
                }
            } catch (e: Exception) {
                android.util.Log.w("sp_ts", "HomeFragment loadMarketData failed: ${e.message}", e)
            }
        }
    }

    companion object {
        private const val TAG_BANNER = "HomeBanner"
    }

    private fun handleBannerClick(item: BannerItem) {
        if (item.link.isNotEmpty()) {
            (activity as? FragmentActivity)?.let { BrowserUtils.openBrowser(it, item.link) }
        }
    }

    override fun initData() {
        android.util.Log.d("sp_ts", "HomeFragment initData")
        loadHomeConfigNames()
        loadMarketData()
        if (UserConfig.isLogin()) {
            loadBanners()
            loadSinglePopup() // 中签与新股提醒只展示一个，优先中签，避免弹窗重叠
        }
    }

    private fun loadHomeConfigNames() {
        viewLifecycleOwner.lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            if (!response.isSuccess()) return@launch
            val config = response.data ?: return@launch
            val dzName = config.dz_syname.trim()
            if (dzName.isNotEmpty()) {
                binding.tvOtcName.text = dzName
            }
            val strategyName = config.is_xxps_name.trim()
            if (strategyName.isNotEmpty()) {
                binding.tvStrategyName.text = strategyName
            }
        }
    }

    /**
     * 弹窗不重叠：两个都有的情况下先展示中签，关闭后再展示新股提醒；只有一个则只展示那一个。
     */
    private fun loadSinglePopup() {
        if (ipoReminderShown || winningDialogShown || !UserConfig.isLogin()) return
        viewLifecycleOwner.lifecycleScope.launch {
            val ballotDeferred = async {
                runCatching {
                    val response = ContractRemote.callApiSilent { getBallotList() }
                    if (!response.isSuccess()) return@runCatching emptyList<MyIpoItem>()
                    val list = response.data?.info.orEmpty()
                    // 优先按 sy_renjiao > 0 作为“未认缴完成”的判断；若后端暂未下发该字段则回退到 renjiao == "0"
                    val byRemain = list.filter { it.sy_renjiao > 0.0 }
                    if (byRemain.isNotEmpty()) {
                        byRemain
                    } else {
                        list.filter { it.renjiao == "0" }
                    }
                }.getOrElse { emptyList() }
            }
            val ipoDeferred = async {
                runCatching {
                    val response = Remote.callApi { getIpoList(page = 1, type = 0) }
                    if (!response.isSuccess()) return@runCatching emptyList()
                    response.data?.list
                        ?.flatMap { it.sub_info }
                        ?.filter { it.sgswitch == 1 }
                        .orEmpty() ?: emptyList()
                }.getOrElse { emptyList() }
            }
            val pendingList = ballotDeferred.await()
            val ipoItems = ipoDeferred.await()
            withContext(Dispatchers.Main.immediate) {
                if (!isAdded) return@withContext
                when {
                    pendingList.isNotEmpty() && ipoItems.isNotEmpty() -> {
                        // 两个都有：先中签，关闭后再弹新股提醒
                        winningDialogShown = true
                        showWinningLotDialog(pendingList) {
                            if (isAdded && !ipoReminderShown) {
                                ipoReminderShown = true
                                IpoReminderDialog.show(childFragmentManager) {
                                    this.items = ipoItems
                                    onGoSubscribe = {
                                        com.yanshu.app.ui.ipo.NewStockSubscriptionActivity.start(requireContext())
                                    }
                                }
                            }
                        }
                    }
                    pendingList.isNotEmpty() -> {
                        winningDialogShown = true
                        showWinningLotDialog(pendingList)
                    }
                    ipoItems.isNotEmpty() -> {
                        ipoReminderShown = true
                        IpoReminderDialog.show(childFragmentManager) {
                            this.items = ipoItems
                            onGoSubscribe = {
                                com.yanshu.app.ui.ipo.NewStockSubscriptionActivity.start(requireContext())
                            }
                        }
                    }
                }
            }
        }
    }

    /** @param onDismiss 中签弹窗关闭后回调，用于再弹新股提醒（可选） */
    private fun showWinningLotDialog(pendingList: List<MyIpoItem>, onDismiss: (() -> Unit)? = null) {
        val first = pendingList.first()
        // 优先使用后端返回的剩余认缴金额 sy_renjiao；如果为 0 或未返回，则回退为总中签金额
        val amount = if (first.sy_renjiao > 0.0) first.sy_renjiao else first.sg_fx_price * first.zq_num

        WinningLotDialog.show(childFragmentManager) {
            stockName = first.name
            stockCode = first.code
            quantity = "${first.zq_nums}手"
            this.amount = "￥%.2f".format(amount)
            winningCount = pendingList.size
            onGoPay = { MyIpoActivity.start(requireContext(), initialTab = 1) } // 1=中签 Tab
            this.onDismiss = onDismiss
        }
    }

    private fun showToast(message: String) {
        AppToast.show(message)
    }

    override fun onResume() {
        super.onResume()
        if (binding.topBanner.visibility == View.VISIBLE) {
            binding.topBanner.start()
        }
    }

    override fun onStop() {
        binding.topBanner.stop()
        super.onStop()
    }

    override fun onDestroyView() {
        super.onDestroyView()
    }
    
    data class NewsItem(
        val rank: Int,
        val title: String,
        val time: String,
        val id: String = ""  // 对应接口 news_id，点击进详情时传入；假数据可传 ""
    )
    
    class NewsAdapter(
        private val items: List<NewsItem>,
        private val showRankIcon: Boolean,  // 是否显示排名图标
        private val onClick: (NewsItem) -> Unit
    ) : RecyclerView.Adapter<NewsAdapter.ViewHolder>() {
        
        class ViewHolder(val binding: ItemHomeNewsBinding) : RecyclerView.ViewHolder(binding.root)
        
        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val binding = ItemHomeNewsBinding.inflate(
                LayoutInflater.from(parent.context), parent, false
            )
            return ViewHolder(binding)
        }
        
        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val item = items[position]
            holder.binding.tvNewsTitle.text = item.title
            holder.binding.tvNewsTime.text = item.time
            
            // 只有动态Tab且前4条显示排名图标
            if (showRankIcon) {
                val listRank = position + 1
                when (listRank) {
                    1 -> {
                        holder.binding.ivRank.visibility = View.VISIBLE
                        holder.binding.ivRank.setImageResource(R.drawable.ic_home_rank_1)
                    }
                    2 -> {
                        holder.binding.ivRank.visibility = View.VISIBLE
                        holder.binding.ivRank.setImageResource(R.drawable.ic_home_rank_2)
                    }
                    3 -> {
                        holder.binding.ivRank.visibility = View.VISIBLE
                        holder.binding.ivRank.setImageResource(R.drawable.ic_home_rank_3)
                    }
                    4 -> {
                        holder.binding.ivRank.visibility = View.VISIBLE
                        holder.binding.ivRank.setImageResource(R.drawable.ic_home_rank_4)
                    }
                    else -> {
                        holder.binding.ivRank.visibility = View.INVISIBLE
                    }
                }
            } else {
                // 非动态Tab不显示图标
                holder.binding.ivRank.visibility = View.GONE
            }
            
            holder.itemView.setOnClickListener { onClick(item) }
        }
        
        override fun getItemCount() = items.size
    }
}
