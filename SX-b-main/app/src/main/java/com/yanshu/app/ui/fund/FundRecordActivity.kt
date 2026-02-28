package com.yanshu.app.ui.fund

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
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
import com.yanshu.app.databinding.ActivityFundRecordBinding
import com.yanshu.app.databinding.ItemFundRecordBinding
import com.yanshu.app.data.CapitalLogItem
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.util.CustomerServiceNavigator
import com.yanshu.app.util.TabIndicatorHelper
import ex.ss.lib.base.adapter.data.BaseItem
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FundRecordActivity : BasicActivity<ActivityFundRecordBinding>() {

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, FundRecordActivity::class.java))
        }
    }

    override val binding: ActivityFundRecordBinding by viewBinding()

    private var currentTabIndex = 0
    private lateinit var tabIndicatorHelper: TabIndicatorHelper
    private lateinit var adapter: FundRecordAdapter
    private val tabs = mutableListOf<TextView>()

    override fun initView() {
        setupTitleBar()
        setupTabs()
        setupRecyclerView()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = "资金记录"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        
        // 右侧客服图标
        binding.titleBar.tvMenu.visibility = View.VISIBLE
        binding.titleBar.tvMenu.text = ""
        binding.titleBar.tvMenu.setCompoundDrawablesWithIntrinsicBounds(
            0, 0, R.drawable.ic_trade_record_service, 0
        )
        binding.titleBar.tvMenu.setOnClickListener {
            CustomerServiceNavigator.open(this, lifecycleScope)
        }
    }

    private fun setupTabs() {
        tabs.clear()
        tabs.add(binding.tabDetail)
        tabs.add(binding.tabTransferIn)
        tabs.add(binding.tabTransferOut)

        // 使用 TabIndicatorHelper 管理指示器
        tabIndicatorHelper = TabIndicatorHelper.create(
            tabs = tabs,
            indicator = binding.tabIndicator
        )

        tabs.forEachIndexed { index, tab ->
            tab.setOnClickListener {
                selectTab(index)
            }
        }

        // 初始化指示器位置
        binding.tabIndicator.post {
            tabIndicatorHelper.init(0)
            selectTab(0, animate = false)
        }
    }

    private fun selectTab(index: Int, animate: Boolean = true) {
        currentTabIndex = index
        
        // 更新 Tab 样式
        tabs.forEachIndexed { i, tab ->
            if (i == index) {
                tab.setTextColor(ContextCompat.getColor(this, R.color.fund_tab_selected))
            } else {
                tab.setTextColor(ContextCompat.getColor(this, R.color.fund_tab_unselected))
            }
        }
        
        // 移动指示器
        tabIndicatorHelper.selectTab(index, animate)
        
        // 加载对应 Tab 的数据
        loadData(index)
    }

    private fun setupRecyclerView() {
        adapter = FundRecordAdapter()
        binding.rvRecords.layoutManager = LinearLayoutManager(this)
        binding.rvRecords.adapter = adapter
    }

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

    override fun initData() {
        loadData(0)
    }

    private fun loadData(tabIndex: Int) {
        val type = when (tabIndex) {
            0 -> null   // 资金明细：不传 type 查全部
            1 -> 0      // 转入记录
            2 -> 1      // 转出记录
            else -> null
        }
        binding.rvRecords.visibility = View.GONE
        binding.tvEmpty.visibility = View.VISIBLE
        binding.tvEmpty.text = "加载中..."

        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getCapitalLog(type) }
            val list = when {
                !response.isSuccess() -> emptyList()
                else -> response.data.list.orEmpty().map { it.toFundRecord() }
            }
            if (list.isEmpty()) {
                binding.rvRecords.visibility = View.GONE
                binding.tvEmpty.visibility = View.VISIBLE
                binding.tvEmpty.text = "暂无数据"
                adapter.submitList(emptyList())
            } else {
                binding.rvRecords.visibility = View.VISIBLE
                binding.tvEmpty.visibility = View.GONE
                adapter.submitList(list)
            }
        }
    }

    private fun CapitalLogItem.toFundRecord(): FundRecord {
        val dateTime = if (createtime > 0) dateFormat.format(Date(createtime * 1000)) else ""
        val detail = buildString {
            append(pay_type_name)
            if (is_pay_name.isNotEmpty()) append("，").append(is_pay_name)
            if (reject.isNotEmpty()) append("，").append(reject)
        }
        return FundRecord(
            type = pay_type_name.ifEmpty { "资金变动" },
            amount = money,
            dateTime = dateTime,
            detail = detail.ifEmpty { "—" }
        )
    }
}

/**
 * 资金记录数据
 */
data class FundRecord(
    val type: String,
    val amount: Double,
    val dateTime: String,
    val detail: String
) : BaseItem

/**
 * 资金记录适配器
 */
class FundRecordAdapter : RecyclerView.Adapter<FundRecordAdapter.ViewHolder>() {

    private val items = mutableListOf<FundRecord>()

    class ViewHolder(val binding: ItemFundRecordBinding) : RecyclerView.ViewHolder(binding.root)

    fun submitList(list: List<FundRecord>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemFundRecordBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val record = items[position]
        holder.binding.apply {
            tvType.text = record.type
            tvAmount.text = String.format("%,.2f", record.amount)
            tvDatetime.text = record.dateTime
            tvDetail.text = record.detail
        }
    }

    override fun getItemCount() = items.size
}
