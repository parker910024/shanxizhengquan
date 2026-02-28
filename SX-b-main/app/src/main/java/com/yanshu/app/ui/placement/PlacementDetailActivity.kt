package com.yanshu.app.ui.placement

import android.content.Context
import android.content.Intent
import android.text.Editable
import android.text.TextWatcher
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.IPOItem
import com.yanshu.app.databinding.ActivityPlacementDetailBinding
import com.yanshu.app.model.IPOViewModel
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dialog.PlacementKeyDialog
import ex.ss.lib.base.extension.viewBinding

/**
 * 战略配售详情页面
 */
class PlacementDetailActivity : BasicActivity<ActivityPlacementDetailBinding>() {

    override val binding: ActivityPlacementDetailBinding by viewBinding()

    private var stockCode = ""
    private var issuePrice = 0.0
    private var maxQuantity = 10_000_000
    private var miyao = ""
    /** 接口返回的申购秘钥（content），用于校验用户输入是否一致 */
    private var expectedMiyaoFromApi = ""

    private data class PlacementOrder(
        val code: String,
        val quantity: Int,
        val miyao: String,
    )

    companion object {
        /** @param inputMiyao 列表页已输入的申购秘钥，若为空则详情页下单前会弹窗要求输入 */
        fun start(context: Context, item: IPOItem, inputMiyao: String? = null) {
            context.startActivity(Intent(context, PlacementDetailActivity::class.java).apply {
                putExtra("item", item)
                inputMiyao?.let { putExtra("inputMiyao", it) }
            })
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }

        val item = intent.getSerializableExtra("item") as? IPOItem
        val inputMiyao = intent.getStringExtra("inputMiyao")?.takeIf { it.isNotBlank() }
        item?.let { showItemInfo(it, inputMiyao) }

        setupQuantityControls()
        observeViewModel()
    }

    override fun initData() {
        val item = intent.getSerializableExtra("item") as? IPOItem ?: return
        IPOViewModel.loadPlacementDetail(item.id)
    }

    private fun showItemInfo(item: IPOItem, inputMiyao: String? = null) {
        stockCode = item.code
        miyao = inputMiyao ?: item.content
        expectedMiyaoFromApi = item.content
        issuePrice = item.fx_price.toDoubleOrNull() ?: 0.0

        binding.tvTitle.text = item.name
        binding.tvStockCode.text = item.code
        binding.tvIndustry.text = item.industry.ifEmpty { "未知" }
        binding.tvPeRatio.text = "${item.fx_rate}%"
        binding.tvMarket.text = item.getMarketTag()
        binding.tvIssuePrice.text = String.format("%.2f", issuePrice)
        binding.tvIssueTotal.text = String.format("%.2f", (item.fx_num.toDoubleOrNull() ?: 0.0) / 10000)
        updateBuyButton()
    }

    private fun setupQuantityControls() {
        binding.btnMinus.setOnClickListener {
            val qty = getQuantity()
            if (qty > 1) {
                binding.etQuantity.setText((qty - 1).toString())
            }
        }

        binding.btnPlus.setOnClickListener {
            val qty = getQuantity()
            if (qty < maxQuantity) {
                binding.etQuantity.setText((qty + 1).toString())
            }
        }

        binding.etQuantity.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                updateBuyButton()
            }
        })

        binding.btnBuy.setOnClickListener { onBuyClick() }
    }

    private fun observeViewModel() {
        IPOViewModel.placementDetailLiveData.observe(this) { data ->
            data ?: return@observe
            maxQuantity = data.psmax.toIntOrNull() ?: 10_000_000
            val info = data.info

            stockCode = info.code
            if (info.content.isNotBlank()) {
                miyao = info.content
                expectedMiyaoFromApi = info.content
            }
            issuePrice = info.fx_price.toDoubleOrNull() ?: 0.0

            binding.tvStockCode.text = info.code
            binding.tvIndustry.text = info.industry.ifEmpty { "未知" }
            binding.tvPeRatio.text = "${info.fx_rate}%"
            binding.tvMarket.text = info.getMarketText()
            binding.tvIssuePrice.text = String.format("%.2f", issuePrice)
            binding.tvIssueTotal.text = String.format("%.2f", (info.fx_num.toDoubleOrNull() ?: 0.0) / 10000)
            updateBuyButton()
        }

        IPOViewModel.operationResult.observe(this) { result ->
            result ?: return@observe
            val (action, success, errorMsg) = result
            if (action == "buyPlacement") {
                if (success) {
                    showBuySuccessDialog()
                } else {
                    AppToast.show(errorMsg ?: "战略配售失败")
                }
                IPOViewModel.clearOperationResult()
            }
        }
    }

    private fun getQuantity(): Int = binding.etQuantity.text.toString().toIntOrNull() ?: 1

    private fun updateBuyButton() {
        val total = issuePrice * getQuantity() * 100
        binding.btnBuy.text = String.format("¥%.2f 战略配售", total)
    }

    private fun buildOrder(): PlacementOrder? {
        if (stockCode.isEmpty()) {
            AppToast.show("股票代码不能为空")
            return null
        }

        val qty = getQuantity()
        if (qty <= 0) {
            AppToast.show("请输入配售手数")
            return null
        }

        if (qty > maxQuantity) {
            AppToast.show("配售手数不能超过 $maxQuantity")
            return null
        }

        return PlacementOrder(
            code = stockCode,
            quantity = qty,
            miyao = miyao,
        )
    }

    private fun onBuyClick() {
        val order = buildOrder() ?: return
        // 接口返回了 content 才弹密钥输入框并校验；为空则不弹，直接确定配售
        if (expectedMiyaoFromApi.isNotBlank()) {
            PlacementKeyDialog.show(supportFragmentManager) { key ->
                val input = key.trim()
                if (input != expectedMiyaoFromApi) {
                    AppToast.show("秘钥错误")
                    return@show
                }
                miyao = input
                showConfirmThenPlace(order)
            }
        } else {
            miyao = ""
            showConfirmThenPlace(order)
        }
    }

    private fun showConfirmThenPlace(order: PlacementOrder) {
        AppDialog.show(supportFragmentManager) {
            title = "提示"
            content = "确定配售吗？"
            cancel = "取消"
            done = "确定"
            onDone = {
                IPOViewModel.buyPlacement(order.code, order.quantity, miyao)
            }
        }
    }

    private fun showBuySuccessDialog() {
        AppDialog.show(supportFragmentManager) {
            title = "提示"
            content = "战略配售成功"
            done = "确定"
            onDone = { finish() }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        IPOViewModel.clearPlacementDetail()
    }
}
