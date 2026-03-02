package com.yanshu.app.ui.dialog

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.FragmentManager
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.yanshu.app.data.BankCardItem
import com.yanshu.app.databinding.DialogBankCardSelectBinding
import com.yanshu.app.databinding.ItemBankCardSelectBinding
import com.yanshu.app.repo.contract.ContractRemote
import kotlinx.coroutines.launch

/**
 * 底部弹窗：选择银行卡。用于转出页等，点击某张卡即选中并回调后关闭。
 */
class BankCardSelectBottomDialog : BottomSheetDialogFragment() {

    companion object {
        private const val TAG = "BankCardSelectBottomDialog"

        fun show(fm: FragmentManager, onSelected: (BankCardItem) -> Unit) {
            BankCardSelectBottomDialog().apply {
                this.onSelected = onSelected
            }.show(fm, TAG)
        }
    }

    private var onSelected: ((BankCardItem) -> Unit)? = null
    private lateinit var binding: DialogBankCardSelectBinding

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        binding = DialogBankCardSelectBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.rvBankCards.layoutManager = LinearLayoutManager(requireContext())
        loadBankCards()
    }

    override fun onStart() {
        super.onStart()
        val bottomSheet = dialog?.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
        bottomSheet?.let {
            val behavior = BottomSheetBehavior.from(it)
            behavior.state = BottomSheetBehavior.STATE_EXPANDED
            behavior.skipCollapsed = true
        }
    }

    private fun loadBankCards() {
        viewLifecycleOwner.lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getBankCardList() }
            val list = response.data?.list?.data.orEmpty()
            if (list.isEmpty()) {
                binding.rvBankCards.visibility = View.GONE
                binding.tvEmpty.visibility = View.VISIBLE
                return@launch
            }
            binding.tvEmpty.visibility = View.GONE
            binding.rvBankCards.visibility = View.VISIBLE
            binding.rvBankCards.adapter = Adapter(list) { item ->
                onSelected?.invoke(item)
                dismissAllowingStateLoss()
            }
        }
    }

    private class Adapter(
        private val items: List<BankCardItem>,
        private val onItemClick: (BankCardItem) -> Unit,
    ) : RecyclerView.Adapter<Adapter.Holder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
            val b = ItemBankCardSelectBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return Holder(b)
        }

        override fun onBindViewHolder(holder: Holder, position: Int) {
            holder.bind(items[position], onItemClick)
        }

        override fun getItemCount(): Int = items.size

        class Holder(private val b: ItemBankCardSelectBinding) : RecyclerView.ViewHolder(b.root) {
            fun bind(item: BankCardItem, onItemClick: (BankCardItem) -> Unit) {
                b.tvBankName.text = item.displayBankName.ifEmpty { "银行卡" }
                b.tvCardNo.text = item.displayBankCard
                b.root.setOnClickListener { onItemClick(item) }
            }
        }
    }
}
