package com.yanshu.app.ui.hq.detail

import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.config.NewsCache
import com.yanshu.app.data.ApiNewsItem
import com.yanshu.app.databinding.ActivityStockDetailBinding
import com.yanshu.app.databinding.ItemHomeNewsBinding
import com.yanshu.app.ui.deal.BuyActivity
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.hq.detail.model.ChartRenderType
import com.yanshu.app.ui.hq.detail.model.DetailChartTab
import com.yanshu.app.ui.hq.detail.model.DetailNewsTab
import com.yanshu.app.ui.hq.detail.model.SnapshotData
import com.yanshu.app.ui.hq.detail.model.StockDetailViewState
import com.yanshu.app.ui.home.NewsDetailActivity
import com.yanshu.app.ui.search.StockSearchActivity
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import kotlin.math.abs

class StockDetailActivity : BasicActivity<ActivityStockDetailBinding>() {

    companion object {
        private const val EXTRA_CODE = "extra_code"
        private const val EXTRA_NAME = "extra_name"
        private const val EXTRA_MARKET_HINT = "extra_market_hint"
        private const val EXTRA_IS_INDEX = "extra_is_index"

        fun start(
            context: Context,
            code: String,
            name: String,
            marketHint: String? = null,
            isIndex: Boolean = false,
        ) {
            val intent = Intent(context, StockDetailActivity::class.java).apply {
                putExtra(EXTRA_CODE, code)
                putExtra(EXTRA_NAME, name)
                putExtra(EXTRA_MARKET_HINT, marketHint)
                putExtra(EXTRA_IS_INDEX, isIndex)
            }
            context.startActivity(intent)
        }
    }

    override val binding: ActivityStockDetailBinding by viewBinding()

    private val viewModel: StockDetailViewModel by lazy {
        ViewModelProvider(this)[StockDetailViewModel::class.java]
    }
    private val pollHandler = Handler(Looper.getMainLooper())
    private var polling = false
    private var currentPreClose: Double? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!polling) return
            viewModel.refreshSnapshot(showError = false)
            pollHandler.postDelayed(this, 5000L)
        }
    }

    private var currentNewsTabIndex = 0

    private val chartTabs by lazy {
        listOf(binding.tabTime, binding.tab5m, binding.tabDayK, binding.tabWeekMonth)
    }
    private val newsTabs by lazy {
        linkedMapOf(
            DetailNewsTab.DYNAMIC to binding.tabNewsDynamic,
            DetailNewsTab.FAST_24 to binding.tabNews24,
            DetailNewsTab.MARKET to binding.tabNewsMarket,
            DetailNewsTab.ADVISER to binding.tabNewsAdviser,
            DetailNewsTab.IMPORTANT to binding.tabNewsImportant,
        )
    }

    override fun initView() {
        setupTopBar()
        setupChartTabs()
        setupNewsTabs()
        setupBottomActions()
        setupNewsList()
        observeViewModel()
    }

    override fun initData() {
        val code = intent.getStringExtra(EXTRA_CODE).orEmpty()
        val name = intent.getStringExtra(EXTRA_NAME).orEmpty()
        val marketHint = intent.getStringExtra(EXTRA_MARKET_HINT)
        val isIndex = intent.getBooleanExtra(EXTRA_IS_INDEX, false)
        if (code.isBlank()) {
            AppToast.show("缺少股票代码")
            finish()
            return
        }
        viewModel.initialize(code, name, marketHint, isIndex)
    }

    override fun onResume() {
        super.onResume()
        startPolling()
    }

    override fun onPause() {
        super.onPause()
        stopPolling()
    }

    override fun onDestroy() {
        stopPolling()
        super.onDestroy()
    }

    private fun setupTopBar() {
        binding.ivBack.setOnClickListener { finish() }
        binding.ivService.setOnClickListener {
            CustomerServiceNavigator.open(this, lifecycleScope)
        }
        binding.ivSearch.setOnClickListener {
            startActivity(Intent(this, StockSearchActivity::class.java))
        }
    }

    private fun setupChartTabs() {
        binding.tabTime.setOnClickListener { viewModel.onTimeTabClick() }
        binding.tab5m.setOnClickListener { viewModel.onFiveMinTabClick() }
        binding.tabDayK.setOnClickListener { viewModel.onDayKTabClick() }
        binding.tabWeekMonth.setOnClickListener { viewModel.onWeekMonthTabClick() }
    }

    private fun setupNewsTabs() {
        newsTabs.entries.forEachIndexed { index, (tab, view) ->
            view.setOnClickListener {
                currentNewsTabIndex = index
                viewModel.onNewsTabClick(tab)
                loadNewsForTab(index)
            }
        }
        binding.tabNewsMore.visibility = View.GONE
    }

    private fun getNewsTypeForTab(index: Int): Int = when (index) {
        0 -> 1
        1 -> 2
        2 -> 3
        3 -> 3
        4 -> 4
        else -> 1
    }

    private fun loadNewsForTab(tabIndex: Int) {
        val type = getNewsTypeForTab(tabIndex)
        val list = NewsCache.getNews(type)
        val showRank = tabIndex == 0
        binding.rvNews.adapter = NewsAdapter(list, showRank) { item ->
            NewsDetailActivity.start(this@StockDetailActivity, item.news_id)
        }
        binding.tvNewsEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun setupBottomActions() {
        binding.btnFavorite.setOnClickListener {
            viewModel.toggleFavorite()
        }
        binding.btnTrade.setOnClickListener {
            if (viewModel.isIndex()) {
                AppToast.show("指数不可交易")
                return@setOnClickListener
            }
            val (quoteCode, buyPrice) = viewModel.currentTradePayload()
            BuyActivity.start(this, allcode = quoteCode, buyPrice = buyPrice)
        }
    }

    private fun setupNewsList() {
        binding.rvNews.layoutManager = LinearLayoutManager(this)
        loadNewsForTab(0)
    }

    private fun observeViewModel() {
        viewModel.viewState.observe(this) { state ->
            renderState(state)
        }
        viewModel.loadingChart.observe(this) { loading ->
            binding.tvChartLoading.visibility = if (loading) View.VISIBLE else View.GONE
        }
        viewModel.chartPayload.observe(this) { payload ->
            binding.tvChartLoading.visibility = View.GONE
            when (payload.renderType) {
                ChartRenderType.TIME_SHARE -> {
                    binding.timeShareChart.visibility = View.VISIBLE
                    binding.kLineChart.visibility = View.GONE
                    binding.timeShareChart.setData(payload.timeSharePoints, currentPreClose)
                }

                ChartRenderType.K_LINE -> {
                    binding.timeShareChart.visibility = View.GONE
                    binding.kLineChart.visibility = View.VISIBLE
                    binding.kLineChart.setData(payload.kLinePoints)
                }
            }
        }
        viewModel.orderBook.observe(this) { book ->
            renderOrderBook(book)
        }
        viewModel.message.observe(this) { msg ->
            if (!msg.isNullOrBlank()) {
                AppToast.show(msg)
            }
        }
    }

    private fun renderOrderBook(book: com.yanshu.app.ui.hq.detail.model.OrderBookData) {
        if (viewModel.isIndex()) {
            binding.layoutOrderBook.visibility = View.GONE
            return
        }
        binding.layoutOrderBook.visibility = View.VISIBLE
        // asks[0]=卖1, asks[4]=卖5；UI 从上到下：卖5→卖1
        val askPrices = listOf(binding.tvAsk5Price, binding.tvAsk4Price, binding.tvAsk3Price, binding.tvAsk2Price, binding.tvAsk1Price)
        val askVols   = listOf(binding.tvAsk5Vol,   binding.tvAsk4Vol,   binding.tvAsk3Vol,   binding.tvAsk2Vol,   binding.tvAsk1Vol)
        for (i in 0..4) {
            val level = book.asks.getOrNull(4 - i)
            askPrices[i].text = formatPrice(level?.price)
            askVols[i].text   = if ((level?.volume ?: 0) > 0) level!!.volume.toString() else "--"
        }
        // bids[0]=买1, bids[4]=买5；UI 从上到下：买1→买5
        val bidPrices = listOf(binding.tvBid1Price, binding.tvBid2Price, binding.tvBid3Price, binding.tvBid4Price, binding.tvBid5Price)
        val bidVols   = listOf(binding.tvBid1Vol,   binding.tvBid2Vol,   binding.tvBid3Vol,   binding.tvBid4Vol,   binding.tvBid5Vol)
        for (i in 0..4) {
            val level = book.bids.getOrNull(i)
            bidPrices[i].text = formatPrice(level?.price)
            bidVols[i].text   = if ((level?.volume ?: 0) > 0) level!!.volume.toString() else "--"
        }
    }

    private fun renderState(state: StockDetailViewState) {
        binding.tvTitle.text = state.title
        binding.tabWeekMonth.text = state.weekMonthMode.label
        renderSnapshot(state.snapshot)
        renderChartTabState(state.chartTab)
        renderNewsTabState(state.newsTab)
        if (state.isIndex) {
            binding.layoutOrderBook.visibility = View.GONE
        }
        renderFavoriteState(state.favorite)
        renderTradeState(state.tradeEnabled)
    }

    private fun renderSnapshot(snapshot: SnapshotData) {
        currentPreClose = snapshot.preClose

        binding.tvPrice.text = formatPrice(snapshot.price)
        binding.tvChange.text = formatSigned(snapshot.change)
        binding.tvChangePct.text = formatSignedPercent(snapshot.changePct)

        binding.tvOpen.text = formatPrice(snapshot.open)
        binding.tvPreClose.text = formatPrice(snapshot.preClose)
        binding.tvLimitUp.text = formatPrice(snapshot.limitUp)
        binding.tvLimitDown.text = formatPrice(snapshot.limitDown)
        binding.tvAmplitude.text = formatPercent(snapshot.amplitudePct)
        binding.tvLow.text = formatPrice(snapshot.low)
        binding.tvHigh.text = formatPrice(snapshot.high)
        binding.tvVolume.text = formatVolume(snapshot.volume)
        binding.tvAmount.text = formatAmount(snapshot.amount)

        val change = snapshot.change ?: 0.0
        val color = when {
            change > 0 -> R.color.hq_rise_color
            change < 0 -> R.color.hq_fall_color
            else -> R.color.hq_text_gray
        }
        val resolvedColor = ContextCompat.getColor(this, color)
        binding.tvPrice.setTextColor(resolvedColor)
        binding.tvChange.setTextColor(resolvedColor)
        binding.tvChangePct.setTextColor(resolvedColor)
    }

    private fun renderChartTabState(selected: DetailChartTab) {
        chartTabs.forEach { tab ->
            val isSelected = when (tab.id) {
                R.id.tab_time -> selected == DetailChartTab.TIME
                R.id.tab_5m -> selected == DetailChartTab.FIVE_MIN
                R.id.tab_day_k -> selected == DetailChartTab.DAY_K
                R.id.tab_week_month -> selected == DetailChartTab.WEEK_MONTH
                else -> false
            }
            tab.setTextColor(
                ContextCompat.getColor(
                    this,
                    if (isSelected) R.color.hq_title_color else R.color.hq_text_gray,
                )
            )
            tab.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    private fun renderNewsTabState(selected: DetailNewsTab) {
        newsTabs.forEach { (tab, view) ->
            val isSelected = tab == selected
            view.setTextColor(
                ContextCompat.getColor(
                    this,
                    if (isSelected) R.color.hq_title_color else R.color.hq_text_gray,
                )
            )
            view.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
        }
        moveNewsIndicator(newsTabs[selected])
    }

    private fun renderFavoriteState(favorite: Boolean) {
        binding.btnFavorite.text = if (favorite) "已加自选" else "加入自选"
        binding.btnFavorite.setTextColor(
            ContextCompat.getColor(
                this,
                if (favorite) R.color.hq_rise_color else R.color.hq_favorite_btn_color,
            )
        )
        binding.btnFavorite.setBackgroundResource(
            if (favorite) {
                R.drawable.bg_stock_detail_favorite_active
            } else {
                R.drawable.bg_stock_detail_favorite_normal
            }
        )
    }

    private fun renderTradeState(enabled: Boolean) {
        binding.btnTrade.text = if (enabled) "交易" else "指数不可交易"
        binding.btnTrade.setBackgroundResource(
            if (enabled) R.drawable.bg_btn_red else R.drawable.bg_stock_detail_trade_disabled
        )
        binding.btnTrade.setTextColor(
            ContextCompat.getColor(
                this,
                if (enabled) R.color.white else R.color.hq_text_gray,
            )
        )
    }

    private fun moveNewsIndicator(view: TextView?) {
        if (view == null) return
        view.post {
            val x = view.left + (view.width - binding.newsIndicator.width) / 2f
            binding.newsIndicator.animate()
                .translationX(x)
                .setDuration(160)
                .start()
        }
    }

    private fun startPolling() {
        if (polling) return
        polling = true
        pollHandler.removeCallbacks(pollRunnable)
        pollHandler.postDelayed(pollRunnable, 5000L)
    }

    private fun stopPolling() {
        polling = false
        pollHandler.removeCallbacks(pollRunnable)
    }

    private fun formatPrice(value: Double?): String {
        return value?.let { String.format("%.2f", it) } ?: "--"
    }

    private fun formatSigned(value: Double?): String {
        if (value == null) return "--"
        val sign = if (value > 0) "+" else ""
        return String.format("%s%.2f", sign, value)
    }

    private fun formatPercent(value: Double?): String {
        return value?.let { String.format("%.2f%%", it) } ?: "--"
    }

    private fun formatSignedPercent(value: Double?): String {
        if (value == null) return "--"
        val sign = if (value > 0) "+" else ""
        return String.format("%s%.2f%%", sign, value)
    }

    private fun formatVolume(value: Double?): String {
        if (value == null) return "--"
        val absValue = abs(value)
        return when {
            absValue >= 100000000 -> String.format("%.2f亿", value / 100000000.0)
            absValue >= 10000 -> String.format("%.2f万", value / 10000.0)
            else -> String.format("%.0f", value)
        }
    }

    private fun formatAmount(value: Double?): String {
        if (value == null) return "--"
        val absValue = abs(value)
        return when {
            absValue >= 1000000000000 -> String.format("%.2f万亿", value / 1000000000000.0)
            absValue >= 100000000 -> String.format("%.2f亿", value / 100000000.0)
            absValue >= 10000 -> String.format("%.2f万", value / 10000.0)
            else -> String.format("%.2f", value)
        }
    }

    private class NewsAdapter(
        private val items: List<ApiNewsItem>,
        private val showRankIcon: Boolean,
        private val onClick: (ApiNewsItem) -> Unit,
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
            holder.binding.tvNewsTitle.text = item.news_title
            holder.binding.tvNewsTime.text = item.news_time_text.ifEmpty { item.news_time }
            if (showRankIcon) {
                val rankRes = when (position + 1) {
                    1 -> R.drawable.ic_home_rank_1
                    2 -> R.drawable.ic_home_rank_2
                    3 -> R.drawable.ic_home_rank_3
                    4 -> R.drawable.ic_home_rank_4
                    else -> null
                }
                if (rankRes != null) {
                    holder.binding.ivRank.visibility = View.VISIBLE
                    holder.binding.ivRank.setImageResource(rankRes)
                } else {
                    holder.binding.ivRank.visibility = View.INVISIBLE
                }
            } else {
                holder.binding.ivRank.visibility = View.GONE
            }
            holder.itemView.setOnClickListener { onClick(item) }
        }

        override fun getItemCount() = items.size
    }
}
