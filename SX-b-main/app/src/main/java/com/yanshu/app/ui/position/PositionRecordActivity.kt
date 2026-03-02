package com.yanshu.app.ui.position

import android.content.Context
import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.data.MyIpoItem
import com.yanshu.app.databinding.ActivityPositionRecordBinding
import com.yanshu.app.databinding.ItemPositionRecordBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.deal.BuyActivity
import com.yanshu.app.ui.hq.detail.StockDetailActivity
import com.yanshu.app.util.TabIndicatorHelper
import ex.ss.lib.base.adapter.data.BaseItem
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class PositionRecordActivity : BasicActivity<ActivityPositionRecordBinding>() {

    companion object {
        private const val EXTRA_INITIAL_TAB = "initial_tab"

        fun start(context: Context, initialTab: Int = 0) {
            context.startActivity(Intent(context, PositionRecordActivity::class.java).apply {
                putExtra(EXTRA_INITIAL_TAB, initialTab)
            })
        }
    }

    override val binding: ActivityPositionRecordBinding by viewBinding()

    private var currentTabIndex = 0
    private var hasResumedOnce = false
    private lateinit var tabIndicatorHelper: TabIndicatorHelper
    private lateinit var adapter: PositionRecordAdapter
    private val tabs = mutableListOf<TextView>()
    private val historyDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private var blockTradeName = "大宗交易"

    private val headerTitles = arrayOf(
        arrayOf("名称/代码", "市值/数量", "现价/买入", "盈亏 / 涨幅"), // 当前持仓
        arrayOf("名称/代码", "买入/数量", "卖出/金额", "盈亏"),       // 历史持仓
        arrayOf("名称/代码", "市值/数量", "现价/买入", "盈亏"),       // 新股持仓
        arrayOf("名称/代码", "价格/数量", "状态", "中签/金额"),
    )

    override fun initView() {
        setupTitleBar()
        setupTabs()
        setupRecyclerView()
    }

    private fun setupTitleBar() {
        binding.ivBack.setOnClickListener { finish() }
    }

    private fun setupTabs() {
        tabs.clear()
        tabs.add(binding.tabCurrent)
        tabs.add(binding.tabHistory)
        tabs.add(binding.tabNewStock)
        tabs.add(binding.tabSubscription)

        tabIndicatorHelper = TabIndicatorHelper.create(
            tabs = tabs,
            indicator = binding.tabIndicator
        )

        tabs.forEachIndexed { index, tab ->
            tab.setOnClickListener {
                selectTab(index)
            }
        }

        binding.tabIndicator.post {
            tabIndicatorHelper.init(0)
            selectTab(0, animate = false)
        }
    }

    private fun selectTab(index: Int, animate: Boolean = true) {
        currentTabIndex = index
        tabIndicatorHelper.selectTab(index, animate)
        updateHeaders(index)
        loadData(index)
    }

    private fun updateHeaders(tabIndex: Int) {
        val titles = headerTitles[tabIndex]
        binding.tvHeader1.text = titles[0]
        binding.tvHeader2.text = titles[1]
        binding.tvHeader3.text = titles[2]
        binding.tvHeader4.text = titles[3]
    }

    private fun setupRecyclerView() {
        adapter = PositionRecordAdapter(
            onSellClick = { holdingItem ->
                verifySellAndNavigate(holdingItem)
            },
            onDetailClick = { holdingItem, isHistory ->
                HoldingDetailActivity.start(this, holdingItem, isHistory)
            },
            onStockClick = { record ->
                val allcode = record.holdingItem?.allcode ?: ""
                StockDetailActivity.start(this, record.code, record.stockName, allcode)
            }
        )
        binding.rvRecords.layoutManager = LinearLayoutManager(this)
        binding.rvRecords.adapter = adapter
    }

    /** 大宗持仓(buytype=7)与普通持仓不在同一表，mrSellLst 不返回大宗，故大宗直接跳转卖出页，以接口返回为准 */
    private fun verifySellAndNavigate(holdingItem: HoldingItem) {
        if (holdingItem.buytype == "7") {
            BuyActivity.startForSell(this@PositionRecordActivity, holdingItem)
            return
        }
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getMrSellList(holdingItem.code) }
            val sellList = resp.data ?: emptyList()
            val match = sellList.find { it.allcode.equals(holdingItem.allcode, ignoreCase = true) }
            val sellableLots = match?.canBuy?.toIntOrNull() ?: 0
            if (match == null || sellableLots <= 0) {
                com.yanshu.app.ui.dialog.AppToast.show("该股票暂不可卖出（T+N限制未到期）")
                return@launch
            }
            BuyActivity.startForSell(this@PositionRecordActivity, holdingItem)
        }
    }

    override fun initData() {
        loadBlockTradeName()
        val initialTab = intent.getIntExtra(EXTRA_INITIAL_TAB, 0).coerceIn(0, tabs.size - 1)
        if (initialTab != 0) {
            binding.tabIndicator.post { selectTab(initialTab) }
        } else {
            loadData(0)
        }
    }

    private fun loadBlockTradeName() {
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val name = response.data?.dz_syname?.trim()
            if (!name.isNullOrEmpty()) {
                blockTradeName = name
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (!hasResumedOnce) {
            hasResumedOnce = true
            return
        }
        loadData(currentTabIndex)
    }

    private fun loadData(tabIndex: Int) {
        when (tabIndex) {
            0 -> loadCurrentHolding()
            1 -> loadHistoryHolding()
            2 -> loadBlockTradeHolding()
            3 -> loadSubscriptionRecords()
        }
    }

    private fun showLoading() {
        binding.rvRecords.visibility = View.GONE
        binding.tvEmpty.visibility = View.VISIBLE
        binding.tvEmpty.text = "加载中..."
    }

    private fun applyList(dataList: List<PositionRecord>) {
        binding.tvEmpty.text = "暂无数据"
        if (dataList.isEmpty()) {
            binding.rvRecords.visibility = View.GONE
            binding.tvEmpty.visibility = View.VISIBLE
        } else {
            binding.rvRecords.visibility = View.VISIBLE
            binding.tvEmpty.visibility = View.GONE
            adapter.submitList(dataList)
        }
    }

    /** Tab 0 - 当前持仓：文档 3.30 /api/deal/getNowWarehouse */
    private fun historyDateRange(): Pair<String, String> {
        val end = Calendar.getInstance()
        val start = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -365) }
        return historyDateFormat.format(start.time) to historyDateFormat.format(end.time)
    }

    private fun loadCurrentHolding() {
        showLoading()
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getDealHoldingList() }
            val list = response.data?.list ?: emptyList()
            val records = list.map { it.toCurrentRecord() }
            applyList(records)
        }
    }

    /** Tab 1 - 历史持仓：先查默认 status=2；为空时兼容回退 status=3（与其他端一致） */
    private fun loadHistoryHolding() {
        showLoading()
        lifecycleScope.launch {
            val (sTime, eTime) = historyDateRange()
            val response = ContractRemote.callApiSilent {
                getDealHistoryLishi(sTime = sTime, eTime = eTime)
            }
            var list = response.data?.list ?: emptyList()
            if (list.isEmpty()) {
                val fallbackResponse = ContractRemote.callApiSilent {
                    getDealHistoryLishi(status = 3, sTime = sTime, eTime = eTime)
                }
                list = fallbackResponse.data?.list ?: emptyList()
            }
            val records = list.map { it.toHistoryRecord() }
            applyList(records)
        }
    }

    /** Tab 2 - 新股持仓：后端暂无此接口，显示空状态 */
    private fun loadBlockTradeHolding() {
        applyList(emptyList())
    }

    /** Tab 3 - 申购记录：文档 3.10 /api/subscribe/getsgnewgu0 */
    private fun loadSubscriptionRecords() {
        showLoading()
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getMyIpoList() }
            val list = response.data?.dxlog_list ?: emptyList()
            val records = list.map { it.toSubscriptionRecord() }
            applyList(records)
        }
    }

    private fun HoldingItem.toCurrentRecord(): PositionRecord {
        val market = marketLabel()
        return PositionRecord(
            tradeType = if (buytype == "7") blockTradeName else "普通交易",
            stockName = title.ifEmpty { "-" },
            market = market,
            code = code,
            date = createtime_name,
            // 表格列对应关系（避免重复展示股票名/代码）：
            // 列2=市值/数量 -> value1(市值) value2(数量)
            // 列3=现价/买入 -> value3(现价) value4(买入价)
            value1 = fmt(cityValueDouble()),
            value2 = number,
            value3 = fmt(caiBuyDouble()),
            value4 = fmt(buyprice),
            profit = fmt(profitLoseDouble()),
            // 当前持仓展示涨幅，取后端 profitLose_rate 字段
            profitRatio = profitLose_rate.ifBlank { "--" },
            isUp = profitLoseDouble() >= 0,
            showSell = true,
            holdingItem = this,
        )
    }

    private fun HoldingItem.toHistoryRecord(): PositionRecord {
        val market = marketLabel()
        return PositionRecord(
            tradeType = if (buytype == "7") blockTradeName else "普通交易",
            stockName = title.ifEmpty { "-" },
            market = market,
            code = code,
            date = createtime_name,
            // 列2=买入/数量 -> value1(买入价) value2(数量)
            // 列3=卖出/金额 -> value3(卖出价) value4(金额/本金)
            value1 = fmt(buyprice),
            value2 = number,
            value3 = fmt(caiBuyDouble()),
            value4 = fmtStr(money),
            profit = fmt(profitLoseDouble()),
            profitRatio = "",
            isUp = profitLoseDouble() >= 0,
            isHistory = true,
            holdingItem = this,
        )
    }

    /** 与 API 文档及其他端一致：北交所(type=4) 显示「京」 */
    private fun HoldingItem.marketLabel(): String = when (type) {
        1 -> "沪"; 2 -> "深"; 3 -> "创"; 4 -> "京"; 5 -> "科"; 6 -> "基"; else -> ""
    }

    /** Double 金额格式化，保留两位小数 */
    private fun fmt(value: Double): String = String.format("%.2f", value)

    /** String 金额格式化，转 Double 失败时原样返回 */
    private fun fmtStr(value: String): String {
        val d = value.toDoubleOrNull() ?: return value
        return String.format("%.2f", d)
    }

    private fun MyIpoItem.toSubscriptionRecord(): PositionRecord {
        val statusText = when (status) {
            "0" -> "申购中"; "1" -> "中签"; "2" -> "未中签"; "3" -> "弃购"
            else -> status_txt.ifEmpty { "未知" }
        }
        val isUp = zq_money > 0
        return PositionRecord(
            tradeType = "新股申购",
            stockName = name.ifEmpty { "-" },
            market = "",
            code = code,
            date = createtime_txt,
            // 表头：价格/数量 | 状态 | 中签/金额
            // 第2列：价格/数量 -> value1(价格) value2(数量)
            // 第3列：状态 -> value3(状态) value4(留空)
            // 第4列：中签/金额 -> profit(中签手数) profitRatio(金额)
            value1 = String.format("%.2f", sg_fx_price),
            value2 = zq_nums.toString(),
            value3 = statusText,
            value4 = "",
            profit = zq_nums.toString(),
            profitRatio = String.format("%.2f", zq_money),
            isUp = isUp,
        )
    }
}

/**
 * 持仓记录数据
 */
data class PositionRecord(
    val tradeType: String,  // 新股交易 / 普通交易
    val stockName: String,
    val market: String,
    val code: String,
    val date: String,
    val value1: String,
    val value2: String,
    val value3: String,
    val value4: String,
    val profit: String,
    val profitRatio: String,
    val isUp: Boolean,
    val showSell: Boolean = false,
    val isHistory: Boolean = false,
    val holdingItem: HoldingItem? = null,
) : BaseItem

/**
 * 持仓记录适配器
 */
class PositionRecordAdapter(
    private val onSellClick: ((HoldingItem) -> Unit)? = null,
    private val onDetailClick: ((HoldingItem, Boolean) -> Unit)? = null,
    private val onStockClick: ((PositionRecord) -> Unit)? = null,
) : RecyclerView.Adapter<PositionRecordAdapter.ViewHolder>() {

    private val items = mutableListOf<PositionRecord>()

    class ViewHolder(val binding: ItemPositionRecordBinding) : RecyclerView.ViewHolder(binding.root)

    fun submitList(list: List<PositionRecord>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemPositionRecordBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    // 将文字转为竖向排列
    private fun toVerticalText(text: String): String {
        return text.toCharArray().joinToString("\n")
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val record = items[position]
        val context = holder.itemView.context

        holder.binding.apply {
            tvTradeType.text = toVerticalText(record.tradeType)
            tvStockName.text = record.stockName
            tvMarket.text = record.market
            tvCode.text = record.code
            tvDate.text = record.date

            tvValue1.text = record.value1
            tvValue2.text = record.value2
            tvValue3.text = record.value3
            tvValue4.text = record.value4

            tvProfit.text = record.profit
            tvProfitRatio.text = record.profitRatio
            // 不能用 GONE，否则第二行列数变化导致表头/数据不对齐
            tvProfitRatio.visibility = if (record.profitRatio.isBlank()) View.INVISIBLE else View.VISIBLE

            // 左侧标签点击 → 股票K线详情
            tvTradeType.setOnClickListener { onStockClick?.invoke(record) }

            // 行情按钮 → 股票K线详情
            btnMarket.setOnClickListener { onStockClick?.invoke(record) }

            // 详情按钮
            btnDetail.visibility = if (record.holdingItem != null) View.VISIBLE else View.GONE
            btnDetail.setOnClickListener {
                record.holdingItem?.let { item -> onDetailClick?.invoke(item, record.isHistory) }
            }

            // 卖出按钮
            btnSell.visibility = if (record.showSell && record.holdingItem != null) View.VISIBLE else View.GONE
            btnSell.setOnClickListener {
                record.holdingItem?.let { item -> onSellClick?.invoke(item) }
            }

            // 设置盈亏颜色
            val color = if (record.isUp) {
                ContextCompat.getColor(context, R.color.hq_rise_color)
            } else {
                ContextCompat.getColor(context, R.color.hq_fall_color)
            }
            tvProfit.setTextColor(color)
            tvProfitRatio.setTextColor(color)

            // 设置市场标签背景色
            val marketColor = when (record.market) {
                "沪" -> ContextCompat.getColor(context, R.color.hq_rise_color)
                "深" -> ContextCompat.getColor(context, android.R.color.holo_blue_dark)
                else -> ContextCompat.getColor(context, R.color.hq_rise_color)
            }
            tvMarket.background.setTint(marketColor)
        }
    }

    override fun getItemCount() = items.size
}
