package com.yanshu.app.ui.entrust

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.databinding.ActivityEntrustListBinding
import com.yanshu.app.databinding.ItemEntrustBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class EntrustListActivity : BasicActivity<ActivityEntrustListBinding>() {

    override val binding: ActivityEntrustListBinding by viewBinding()

    private var listJob: Job? = null
    private lateinit var adapter: EntrustAdapter
    private val cancelingIds = mutableSetOf<Int>()
    private val detailLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            loadEntrustList()
        }
    }

    companion object {
        private const val EXTRA_FORCE_REFRESH = "extra_force_refresh"
        private const val EXTRA_FROM_BUY_SUCCESS = "extra_from_buy_success"
        private const val BUY_SUCCESS_REFRESH_RETRY_COUNT = 3
        private const val RETRY_INTERVAL_MS = 400L

        fun start(context: Context, forceRefresh: Boolean = false, fromBuySuccess: Boolean = false) {
            context.startActivity(
                Intent(context, EntrustListActivity::class.java).apply {
                    if (forceRefresh) {
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    }
                    putExtra(EXTRA_FORCE_REFRESH, forceRefresh)
                    putExtra(EXTRA_FROM_BUY_SUCCESS, fromBuySuccess)
                }
            )
        }

        fun startAfterBuySuccess(context: Context) {
            start(context, forceRefresh = true, fromBuySuccess = true)
        }
    }

    override fun initView() {
        setupTitleBar()
        binding.rvEntrust.layoutManager = LinearLayoutManager(this)
        adapter = EntrustAdapter(
            onItemClick = { item -> detailLauncher.launch(EntrustDetailActivity.createIntent(this, item)) },
            onCancel = { item -> onCancel(item) }
        )
        binding.rvEntrust.adapter = adapter
        binding.tvEmpty.setOnClickListener { loadEntrustList() }
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = "委托记录"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    override fun initData() {
        loadBlockTradeName()
        val fromBuySuccess = intent.getBooleanExtra(EXTRA_FROM_BUY_SUCCESS, false)
        val maxAttempts = if (fromBuySuccess) BUY_SUCCESS_REFRESH_RETRY_COUNT else 1
        loadEntrustList(maxAttempts = maxAttempts)
    }

    private fun loadBlockTradeName() {
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val name = response.data?.dz_syname?.trim()
            if (!name.isNullOrEmpty()) {
                adapter.blockTradeName = name
            }
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        val forceRefresh = intent?.getBooleanExtra(EXTRA_FORCE_REFRESH, false) == true
        val fromBuySuccess = intent?.getBooleanExtra(EXTRA_FROM_BUY_SUCCESS, false) == true
        if (forceRefresh || fromBuySuccess) {
            val maxAttempts = if (fromBuySuccess) BUY_SUCCESS_REFRESH_RETRY_COUNT else 1
            loadEntrustList(maxAttempts = maxAttempts)
        }
    }

    private fun loadEntrustList(maxAttempts: Int = 1) {
        listJob?.cancel()
        binding.rvEntrust.visibility = View.GONE
        binding.tvEmpty.visibility = View.VISIBLE
        binding.tvEmpty.text = "加载中..."
        binding.tvEmpty.setOnClickListener(null)
        listJob = lifecycleScope.launch {
            val attemptCount = maxAttempts.coerceAtLeast(1)
            var entrustList: List<HoldingItem> = emptyList()
            var lastError: String? = null

            var attempt = 0
            while (attempt < attemptCount) {
                val response = ContractRemote.callApiSilent {
                    getEntrustList(page = 1, size = 10, buytype = "1,7", status = "2")
                }
                if (response.isSuccess()) {
                    entrustList = response.data.list
                    if (entrustList.isNotEmpty() || attempt == attemptCount - 1) {
                        lastError = null
                        break
                    }
                } else {
                    lastError = response.failed.msg
                    if (attempt == attemptCount - 1) {
                        break
                    }
                }
                attempt++
                delay(RETRY_INTERVAL_MS)
            }
            renderEntrustList(entrustList, lastError)
        }
    }

    private fun renderEntrustList(list: List<HoldingItem>, lastError: String?) {
        cancelingIds.clear()
        adapter.submitList(list)
        adapter.setCancelingIds(cancelingIds)

        if (list.isNotEmpty()) {
            binding.rvEntrust.visibility = View.VISIBLE
            binding.tvEmpty.visibility = View.GONE
            return
        }

        binding.rvEntrust.visibility = View.GONE
        binding.tvEmpty.visibility = View.VISIBLE
        if (!lastError.isNullOrBlank()) {
            binding.tvEmpty.text = "加载失败，点击重试"
            binding.tvEmpty.setOnClickListener { loadEntrustList() }
            AppToast.show(lastError)
        } else {
            binding.tvEmpty.text = "暂无委托记录"
            binding.tvEmpty.setOnClickListener(null)
        }
    }

    private fun onCancel(item: HoldingItem) {
        if (item.status != 2 || item.id <= 0) return
        if (!cancelingIds.add(item.id)) return
        adapter.setCancelingIds(cancelingIds)
        lifecycleScope.launch {
            try {
                val response = ContractRemote.callApi { cancelOrder(item.id) }
                if (response.isSuccess()) {
                    AppToast.show("\u64a4\u5355\u6210\u529f")
                    loadEntrustList()
                }
            } finally {
                cancelingIds.remove(item.id)
                adapter.setCancelingIds(cancelingIds)
            }
        }
    }
}

private class EntrustAdapter(
    private val onItemClick: (HoldingItem) -> Unit,
    private val onCancel: (HoldingItem) -> Unit,
) : RecyclerView.Adapter<EntrustAdapter.Holder>() {

    private val items = mutableListOf<HoldingItem>()
    private val cancelingIds = mutableSetOf<Int>()
    var blockTradeName: String = "大宗"
        set(value) { field = value; notifyDataSetChanged() }

    fun submitList(list: List<HoldingItem>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    fun setCancelingIds(ids: Set<Int>) {
        cancelingIds.clear()
        cancelingIds.addAll(ids)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val b = ItemEntrustBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return Holder(b)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        val item = items[position]
        holder.bind(item, cancelingIds.contains(item.id), blockTradeName, onItemClick, onCancel)
    }

    override fun getItemCount() = items.size

    class Holder(private val b: ItemEntrustBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(
            item: HoldingItem,
            isCanceling: Boolean,
            blockTradeName: String,
            onItemClick: (HoldingItem) -> Unit,
            onCancel: (HoldingItem) -> Unit,
        ) {
            b.tvStockName.text = buildString {
                if (item.title.isNotEmpty()) append(item.title)
                if (item.code.isNotEmpty()) append("  ${item.code}")
                if (isEmpty()) append("-")
            }
            b.tvStatus.text = item.cjlx.ifEmpty { "\u59d4\u6258" }
            b.tvBuyTypeTag.text = when (item.buytype) {
                "7" -> "证券买入($blockTradeName)"
                "1" -> "\u8bc1\u5238\u4e70\u5165"
                else -> item.buytype.ifEmpty { "--" }
            }
            b.tvPrice.text = if (item.buyprice > 0) String.format("%.2f", item.buyprice) else "--"
            b.tvNumber.text = item.number.ifEmpty { "--" }
            b.root.setOnClickListener { onItemClick(item) }

            val canCancel = item.status == 2 && item.id > 0
            b.btnCancel.isVisible = canCancel
            if (canCancel) {
                b.btnCancel.isEnabled = !isCanceling
                b.btnCancel.alpha = if (isCanceling) 0.6f else 1f
                b.btnCancel.text = if (isCanceling) "\u64a4\u5355\u4e2d" else b.root.context.getString(R.string.trade_cancel)
                b.btnCancel.setOnClickListener {
                    if (!isCanceling) onCancel(item)
                }
            } else {
                b.btnCancel.setOnClickListener(null)
            }
        }
    }
}
