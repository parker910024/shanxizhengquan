package com.yanshu.app.ui.contract

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import androidx.appcompat.app.AlertDialog
import androidx.annotation.StringRes
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.ContractItem
import com.yanshu.app.databinding.ActivityContractListBinding
import com.yanshu.app.databinding.ItemContractBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class ContractListActivity : BasicActivity<ActivityContractListBinding>() {

    override val binding: ActivityContractListBinding by viewBinding()

    private val contractList = mutableListOf<ContractItem>()
    private val adapter by lazy {
        ContractAdapter(
            list = contractList,
            onItemClick = ::onItemClick,
            onSignClick = ::onSignClick,
        )
    }

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, ContractListActivity::class.java))
        }
    }

    override fun initView() {
        setupTitleBar()
        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        binding.recyclerView.adapter = adapter
    }

    override fun initData() {
        loadContractList()
    }

    override fun onResume() {
        super.onResume()
        loadContractList()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.contract_title_online)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun toast(@StringRes resId: Int) {
        AppToast.show(getString(resId))
    }

    private fun loadContractList() {
        lifecycleScope.launch {
            binding.progressBar.visibility = View.VISIBLE
            binding.layoutEmpty.visibility = View.GONE
            val response = ContractRemote.callApi { getContractList() }
            binding.progressBar.visibility = View.GONE

            if (response.isSuccess()) {
                val list = response.data
                contractList.clear()
                if (!list.isNullOrEmpty()) {
                    contractList.addAll(list)
                    adapter.notifyDataSetChanged()
                    binding.layoutEmpty.visibility = View.GONE
                } else {
                    adapter.notifyDataSetChanged()
                    binding.layoutEmpty.visibility = View.VISIBLE
                }
            } else {
                contractList.clear()
                adapter.notifyDataSetChanged()
                binding.layoutEmpty.visibility = View.VISIBLE
                AppToast.show(response.failed.msg ?: getString(R.string.contract_load_failed))
            }
        }
    }

    private fun onItemClick(contract: ContractItem) {
        if (contract.isSigned) {
            openContractDetail(contract)
        } else {
            onSignClick(contract)
        }
    }

    private fun onSignClick(contract: ContractItem) {
        if (contract.isSigned) {
            toast(R.string.contract_already_signed)
            return
        }
        if (contract.name.contains("证券投资顾问咨询服务协议")) {
            showAddressDialog(contract)
        } else {
            openContractDetail(contract)
        }
    }

    private fun showAddressDialog(contract: ContractItem) {
        val dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_contract_address, null, false)
        val etAddress = dialogView.findViewById<EditText>(R.id.et_address)

        val dialog = AlertDialog.Builder(this)
            .setView(dialogView)
            .setCancelable(true)
            .create()

        dialogView.findViewById<View>(R.id.btn_cancel).setOnClickListener {
            dialog.dismiss()
        }
        dialogView.findViewById<View>(R.id.btn_confirm).setOnClickListener {
            val address = etAddress.text.toString().trim()
            if (address.isEmpty()) {
                AppToast.show("请输入身份证地址")
                return@setOnClickListener
            }
            dialog.dismiss()
            openContractDetail(contract, address)
        }

        dialog.show()
    }

    private fun openContractDetail(contract: ContractItem, address: String? = null) {
        startActivity(
            ContractDetailActivity.createIntent(
                context = this,
                contractId = contract.id,
                contractType = normalizeContractType(contract.type),
                contractName = contract.name,
            ).apply {
                if (!address.isNullOrEmpty()) {
                    putExtra(ContractDetailActivity.EXTRA_CONTRACT_ADDRESS, address)
                }
            }
        )
    }

    private fun normalizeContractType(type: Int): Int {
        return if (type == 1 || type == 2) type else 1
    }

    private class ContractAdapter(
        private val list: List<ContractItem>,
        private val onItemClick: (ContractItem) -> Unit,
        private val onSignClick: (ContractItem) -> Unit,
    ) : RecyclerView.Adapter<ContractAdapter.ContractViewHolder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ContractViewHolder {
            val binding = ItemContractBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return ContractViewHolder(binding)
        }

        override fun onBindViewHolder(holder: ContractViewHolder, position: Int) {
            holder.bind(list[position], onItemClick, onSignClick)
        }

        override fun getItemCount(): Int = list.size

        class ContractViewHolder(private val binding: ItemContractBinding) :
            RecyclerView.ViewHolder(binding.root) {

            fun bind(
                item: ContractItem,
                onItemClick: (ContractItem) -> Unit,
                onSignClick: (ContractItem) -> Unit,
            ) {
                val context = binding.root.context
                binding.tvName.text = item.name
                binding.root.setOnClickListener { onItemClick(item) }

                if (item.isSigned) {
                    binding.tvStatus.text = context.getString(R.string.contract_status_signed)
                    binding.tvStatus.setTextColor(Color.parseColor("#58BE6A"))
                    binding.tvAction.text = context.getString(R.string.contract_action_signed)
                    binding.tvAction.setBackgroundResource(R.drawable.bg_contract_sign_action_disabled)
                    binding.tvAction.setOnClickListener(null)
                    binding.tvAction.isEnabled = false
                } else {
                    binding.tvStatus.text = context.getString(R.string.contract_status_unsigned)
                    binding.tvStatus.setTextColor(Color.parseColor("#C9292B"))
                    binding.tvAction.text = context.getString(R.string.contract_action_sign)
                    binding.tvAction.setBackgroundResource(R.drawable.bg_contract_sign_action)
                    binding.tvAction.isEnabled = true
                    binding.tvAction.setOnClickListener { onSignClick(item) }
                }
            }
        }
    }
}
