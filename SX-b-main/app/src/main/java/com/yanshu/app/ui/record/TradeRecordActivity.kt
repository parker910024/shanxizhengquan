package com.yanshu.app.ui.record

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityTradeRecordBinding
import com.yanshu.app.databinding.ItemTradeRecordBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class TradeRecordActivity : BasicActivity<ActivityTradeRecordBinding>() {

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, TradeRecordActivity::class.java))
        }
    }

    override val binding: ActivityTradeRecordBinding by viewBinding()

    private lateinit var adapter: TradeRecordAdapter

    override fun initView() {
        setupTitleBar()
        setupRecyclerView()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.trade_record_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener {
            finish()
        }
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

    private fun setupRecyclerView() {
        binding.rvRecords.layoutManager = LinearLayoutManager(this)
        adapter = TradeRecordAdapter(mutableListOf())
        binding.rvRecords.adapter = adapter
    }

    override fun initData() {
        loadTradeHistory()
    }

    private fun loadTradeHistory() {
        binding.tvEmpty.visibility = View.GONE
        lifecycleScope.launch {
            val historyDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val end = historyDateFormat.format(Calendar.getInstance().time)
            val start = historyDateFormat.format(
                Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -365) }.time
            )
            val response = ContractRemote.callApiSilent {
                getDealHistoryLishi(sTime = start, eTime = end)
            }
            var list = response.data?.list ?: emptyList()
            if (list.isEmpty()) {
                val fallbackResponse = ContractRemote.callApiSilent {
                    getDealHistoryLishi(status = 3, sTime = start, eTime = end)
                }
                list = fallbackResponse.data?.list ?: emptyList()
            }
            val records = list.flatMap { item ->
                val name = if (item.title.isNotEmpty() || item.code.isNotEmpty()) "${item.title}(${item.code})" else "-"
                val shares = item.number.toIntOrNull() ?: 0
                val buyAmount = item.money.toDoubleOrNull() ?: 0.0
                val sellAmount = shares * item.cai_buy
                listOf(
                    TradeRecord(TradeType.BUY, name, buyAmount, item.createtime_name, shares),
                    TradeRecord(TradeType.SELL, name, sellAmount, item.outtime_name, shares)
                )
            }.sortedByDescending { it.dateTime }
            adapter.submitList(records)
            binding.tvEmpty.visibility = if (records.isEmpty()) View.VISIBLE else View.GONE
        }
    }
}

enum class TradeType {
    BUY,  // 买入
    SELL  // 卖出
}

data class TradeRecord(
    val type: TradeType,
    val stockName: String,
    val amount: Double,
    val dateTime: String,
    val shares: Int
)

class TradeRecordAdapter(
    private val records: MutableList<TradeRecord> = mutableListOf()
) : RecyclerView.Adapter<TradeRecordAdapter.ViewHolder>() {

    fun submitList(newList: List<TradeRecord>) {
        records.clear()
        records.addAll(newList)
        notifyDataSetChanged()
    }

    class ViewHolder(val binding: ItemTradeRecordBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemTradeRecordBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val record = records[position]
        holder.binding.apply {
            // 设置买入/卖出标签
            when (record.type) {
                TradeType.SELL -> {
                    tvTradeType.text = "卖出"
                    tvTradeType.setTextColor(ContextCompat.getColor(root.context, R.color.trade_sell_color))
                }
                TradeType.BUY -> {
                    tvTradeType.text = "买入"
                    tvTradeType.setTextColor(ContextCompat.getColor(root.context, R.color.trade_buy_color))
                }
            }
            
            // 设置股票名称和金额
            tvStockName.text = record.stockName
            tvAmount.text = String.format("%,.2f", record.amount)
            
            // 设置日期时间和股数
            tvDatetimeShares.text = "${record.dateTime} ${record.shares}股"
        }
    }

    override fun getItemCount() = records.size
}
