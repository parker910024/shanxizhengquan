package com.yanshu.app.ui.bankcard

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.BankCardItem
import com.yanshu.app.databinding.ActivityBankCardListBinding
import com.yanshu.app.databinding.ItemBankCardBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.contract.ContractRemote
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class BankCardListActivity : BasicActivity<ActivityBankCardListBinding>() {

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, BankCardListActivity::class.java))
        }
    }

    override val binding: ActivityBankCardListBinding by viewBinding()

    private lateinit var adapter: BankCardListAdapter

    private val bindResultLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        if (it.resultCode == RESULT_OK) loadData()
    }

    override fun initView() {
        setupTitleBar()
        setupRecyclerView()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = "我的银行卡"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun setupRecyclerView() {
        binding.rvBankCards.layoutManager = LinearLayoutManager(this)
        adapter = BankCardListAdapter(onEdit = { item -> openBindPage(editId = item.id, item = item) })
        binding.rvBankCards.adapter = adapter
        binding.btnAddCard.setOnClickListener { openBindPage(editId = null, item = null) }
    }

    private fun openBindPage(editId: Int?, item: BankCardItem?) {
        val intent = Intent(this, BindBankCardActivity::class.java)
        editId?.let { intent.putExtra(BindBankCardActivity.EXTRA_ID, it) }
        item?.let {
            intent.putExtra(BindBankCardActivity.EXTRA_NAME, it.name)
            intent.putExtra(BindBankCardActivity.EXTRA_DEPOSIT_BANK, it.deposit_bank)
            intent.putExtra(BindBankCardActivity.EXTRA_ACCOUNT, it.account)
            intent.putExtra(BindBankCardActivity.EXTRA_KHZHIHANG, it.khzhihang)
        }
        bindResultLauncher.launch(intent)
    }

    override fun initData() {
        loadData()
    }

    private fun loadData() {
        lifecycleScope.launch {
            // 加载余额数据（T+1资金、可转出金额）
            val priceRes = Remote.callApi { getUserPriceAll() }
            priceRes.data?.list?.let { info ->
                binding.tvT1Amount.text = formatAmount(info.freeze_profit)
                binding.tvTransferableAmount.text = formatAmount(info.balance)
            }

            // 加载银行卡列表
            val response = ContractRemote.callApiSilent { getBankCardList() }
            val responseData = response.data
            val pageData = responseData?.list
            val list = pageData?.data ?: emptyList()

            adapter.submitList(list)
            binding.rvBankCards.visibility = if (list.isEmpty()) View.GONE else View.VISIBLE

            // bindkanums：最大绑卡数；total：已绑数量。已达上限则隐藏添加按钮
            val maxCards = responseData?.bindkanums?.toIntOrNull() ?: Int.MAX_VALUE
            val currentTotal = pageData?.total ?: list.size
            binding.btnAddCard.visibility = if (currentTotal >= maxCards) View.GONE else View.VISIBLE
        }
    }

    private fun formatAmount(value: Double): String =
        if (value == value.toLong().toDouble()) "${value.toLong()}" else "%.2f".format(value)
}

private class BankCardListAdapter(
    private val onEdit: (BankCardItem) -> Unit,
) : RecyclerView.Adapter<BankCardListAdapter.CardHolder>() {

    private val items = mutableListOf<BankCardItem>()

    fun submitList(list: List<BankCardItem>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CardHolder =
        CardHolder(ItemBankCardBinding.inflate(LayoutInflater.from(parent.context), parent, false))

    override fun onBindViewHolder(holder: CardHolder, position: Int) {
        holder.bind(items[position], onEdit)
    }

    override fun getItemCount() = items.size

    class CardHolder(val b: ItemBankCardBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(item: BankCardItem, onEdit: (BankCardItem) -> Unit) {
            b.tvBankName.text = item.displayBankName.ifEmpty { "银行卡" }
            b.tvCardNo.text = item.displayBankCard
            b.tvBranch.text = "开户支行：${item.khzhihang.ifEmpty { "-" }}"
            b.btnEdit.setOnClickListener { onEdit(item) }
        }
    }
}
