package com.yanshu.app.ui.position

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.view.View
import android.view.WindowManager
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.data.SellRequest
import com.yanshu.app.data.SellStockRequest
import com.yanshu.app.databinding.ActivityHoldingDetailBinding
import com.yanshu.app.databinding.DialogTradeConfirmBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import kotlin.math.abs

class HoldingDetailActivity : BasicActivity<ActivityHoldingDetailBinding>() {

    override val binding: ActivityHoldingDetailBinding by viewBinding()

    private var holdingItem: HoldingItem? = null
    private var isHistory = false
    private var readOnly = false
    /** 是否来自撮合交易：点击平仓弹出确认弹窗并直接提交平仓，不跳转卖出页 */
    private var fromBulkTrade = false

    companion object {
        private const val EXTRA_HOLDING = "extra_holding"
        private const val EXTRA_IS_HISTORY = "extra_is_history"
        private const val EXTRA_READ_ONLY = "extra_read_only"
        private const val EXTRA_FROM_BULK_TRADE = "extra_from_bulk_trade"

        fun start(context: Context, item: HoldingItem, isHistory: Boolean = false) {
            context.startActivity(Intent(context, HoldingDetailActivity::class.java).apply {
                putExtra(EXTRA_HOLDING, item)
                putExtra(EXTRA_IS_HISTORY, isHistory)
            })
        }

        /** 撮合交易中进入：详情页显示平仓按钮，点击后弹窗确认并直接平仓 */
        fun startForBulkTrade(context: Context, item: HoldingItem) {
            context.startActivity(Intent(context, HoldingDetailActivity::class.java).apply {
                putExtra(EXTRA_HOLDING, item)
                putExtra(EXTRA_IS_HISTORY, false)
                putExtra(EXTRA_FROM_BULK_TRADE, true)
            })
        }

        fun startReadOnly(context: Context, item: HoldingItem, isHistory: Boolean = false) {
            context.startActivity(Intent(context, HoldingDetailActivity::class.java).apply {
                putExtra(EXTRA_HOLDING, item)
                putExtra(EXTRA_IS_HISTORY, isHistory)
                putExtra(EXTRA_READ_ONLY, true)
            })
        }
    }

    @Suppress("DEPRECATION")
    override fun initView() {
        holdingItem = intent.getSerializableExtra(EXTRA_HOLDING) as? HoldingItem
        isHistory = intent.getBooleanExtra(EXTRA_IS_HISTORY, false)
        readOnly = intent.getBooleanExtra(EXTRA_READ_ONLY, false)
        fromBulkTrade = intent.getBooleanExtra(EXTRA_FROM_BULK_TRADE, false)

        binding.ivBack.setOnClickListener { finish() }

        if (isHistory) {
            binding.tvTitle.text = "历史持仓详情"
            binding.btnAction.text = "返回"
            binding.btnAction.setOnClickListener { finish() }
            binding.tvLabelStockCode.text = "股票"
            binding.tvLabelStockName.text = "买入数量(股)"
            binding.tvLabelQuantity.text = "买入手数"
            binding.tvLabelBuyPrice.text = "买入价格"
            binding.tvLabelMarketValue.text = "本金"
            binding.tvLabelFee.text = "买入手续费"
            binding.tvLabelProfitRate.text = "平仓手续费"
            binding.tvLabelBuyTime.text = "买入时间"
            binding.rowBuyMarketValue.visibility = View.VISIBLE
            binding.rowSellType.visibility = View.VISIBLE
            binding.rowProfitRate.visibility = View.VISIBLE
            binding.rowSellPrice.visibility = View.VISIBLE
            binding.rowStampTax.visibility = View.VISIBLE
            binding.rowSellTime.visibility = View.VISIBLE
        } else if (readOnly) {
            binding.tvTitle.text = "持仓详情"
            binding.btnAction.text = "返回"
            binding.btnAction.setOnClickListener { finish() }
        } else {
            binding.tvTitle.text = "持仓详情"
            binding.btnAction.text = "平仓"
            binding.btnAction.setOnClickListener {
                if (fromBulkTrade) {
                    holdingItem?.let { item -> showConfirmCloseDialog(item) }
                } else {
                    holdingItem?.let { item -> verifySellAndConfirm(item) }
                }
            }
        }

        bindData()
    }

    override fun initData() {}

    private fun verifySellAndConfirm(item: HoldingItem) {
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getMrSellList(item.code) }
            val sellList = resp.data ?: emptyList()
            val match = sellList.find { it.allcode.equals(item.allcode, ignoreCase = true) }
            val sellableLots = match?.canBuy?.toIntOrNull() ?: 0
            if (match == null || sellableLots <= 0) {
                AppToast.show("该股票暂不可卖出（T+N限制未到期）")
                return@launch
            }
            showConfirmCloseDialog(item, sellableLots)
        }
    }

    /** 撮合交易：确认平仓弹窗，点击确认后提交平仓 */
    private fun showConfirmCloseDialog(item: HoldingItem, sellableLots: Int? = null) {
        val price = item.caiBuyDouble().takeIf { it > 0 } ?: item.buyprice
        val shares = (sellableLots?.times(100)) ?: (item.number.toIntOrNull() ?: 0)
        val total = price * shares

        val dialog = Dialog(this)
        dialog.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE)
        val db = DialogTradeConfirmBinding.inflate(layoutInflater)
        dialog.setContentView(db.root)

        db.tvDialogTitle.text = "确认平仓吗?"
        db.btnConfirmOk.text = "确认"
        db.btnConfirmOk.setBackgroundResource(R.drawable.bg_btn_primary)
        db.tvConfirmName.text = item.title.ifBlank { item.code }
        db.tvConfirmPrice.text = formatFixed2(price)
        db.tvConfirmShares.text = shares.toString()
        db.tvConfirmTotal.text = formatFixed2(total)

        db.btnConfirmCancel.setOnClickListener { dialog.dismiss() }
        db.btnConfirmOk.setOnClickListener {
            dialog.dismiss()
            doClosePosition(item, price, shares)
        }

        dialog.window?.apply {
            setLayout(
                (resources.displayMetrics.widthPixels * 0.85).toInt(),
                WindowManager.LayoutParams.WRAP_CONTENT,
            )
            setBackgroundDrawableResource(android.R.color.transparent)
        }
        dialog.show()
    }

    private fun doClosePosition(item: HoldingItem, price: Double, shares: Int) {
        val lots = (shares / 100).coerceAtLeast(0)
        if (lots <= 0) {
            AppToast.show("股数无效")
            return
        }
        binding.btnAction.isEnabled = false
        lifecycleScope.launch {
            val primaryResp = ContractRemote.callApiSilent {
                sell(
                    SellRequest(
                        id = item.id,
                        allcode = item.allcode,
                        canBuy = lots,
                        sellprice = price,
                    )
                )
            }
            val resp = if (!primaryResp.isSuccess() && isApiNotFound(primaryResp.failed.msg)) {
                ContractRemote.callApiSilent {
                    sellStockLegacy(SellStockRequest(id = item.id, sellprice = price, number = shares))
                }
            } else {
                primaryResp
            }
            binding.btnAction.isEnabled = true
            if (resp.isSuccess()) {
                AppDialog.show(supportFragmentManager) {
                    title = "平仓成功"
                    content = "平仓成功"
                    done = "确定"
                    onDone = { finish() }
                }
            } else if (isApiNotFound(resp.failed.msg)) {
                AppToast.show("平仓接口未开放，请联系后端开通")
            } else {
                AppToast.show(resp.failed.msg ?: "平仓失败，请重试")
            }
        }
    }

    private fun isApiNotFound(msg: String?): Boolean {
        val text = msg ?: return false
        return text.contains("api不存在") || text.contains("api not found", ignoreCase = true)
    }

    private fun bindData() {
        val item = holdingItem ?: return

        binding.tvMarket.text = marketLabel(item.type)
        binding.tvStockCode.text = item.code
        // 与 iOS 对齐：按接口 JSON 字段展示，金额/价格保留两位小数
        binding.tvStockName.text = if (isHistory) item.number else item.title
        binding.tvQuantity.text = if (isHistory) formatLots(item.number) else item.number
        binding.tvBuyPrice.text = formatFixed2(item.buyprice)
        if (isHistory) {
            val buyMarketValue = item.buyprice * (item.number.toDoubleOrNull() ?: 0.0)
            binding.tvBuyMarketValue.text = formatFixed2(buyMarketValue)
        }
        binding.tvMarketValue.text = if (isHistory) {
            formatMoneyText(item.money)
        } else {
            formatFixed2(item.cityValueDouble())
        }
        binding.tvFee.text = if (isHistory) "0" else formatFixed2(item.allMoney.toDoubleOrNull() ?: 0.0)
        binding.tvProfit.text = formatFixed2(item.profitLoseDouble())
        if (isHistory) {
            binding.tvProfitRate.text = formatFixed2(item.allMoney.toDoubleOrNull() ?: 0.0)
            binding.tvSellType.text = item.cjlx.ifBlank { "平台" }
        } else {
            binding.tvProfitRate.text = item.profitLose_rate
        }
        binding.tvBuyTime.text = item.createtime_name

        if (isHistory) {
            binding.tvSellPrice.text = formatFixed2(item.caiBuyDouble())
            binding.tvStampTax.text = item.yhfee.toDoubleOrNull()?.let { formatFixed2(it) } ?: item.yhfee
            binding.tvSellTime.text = item.outtime_name
        }

        val profitColor = if (item.profitLoseDouble() >= 0) {
            ContextCompat.getColor(this, R.color.hq_rise_color)
        } else {
            ContextCompat.getColor(this, R.color.hq_fall_color)
        }
        binding.tvProfit.setTextColor(profitColor)
        if (isHistory) {
            binding.tvProfitRate.setTextColor(ContextCompat.getColor(this, R.color.black))
        } else {
            binding.tvProfitRate.setTextColor(profitColor)
        }
    }

    /** 与 API 文档及其他端一致：北交所(type=4) 显示「京」 */
    private fun marketLabel(type: Int): String = when (type) {
        1 -> "沪"; 2 -> "深"; 3 -> "创"; 4 -> "京"; 5 -> "科"; 6 -> "基"; else -> ""
    }

    /** 金额/价格：去掉无意义尾零（10.10 -> 10.1，9480.00 -> 9480） */
    private fun formatTrim(value: Double): String {
        if (abs(value - value.toLong().toDouble()) < 0.000001) {
            return value.toLong().toString()
        }
        return String.format("%.2f", value).trimEnd('0').trimEnd('.')
    }

    /** 盈亏固定两位（与其他端一致） */
    private fun formatFixed2(value: Double): String = String.format("%.2f", value)

    /** 股数转手数（100股=1手） */
    private fun formatLots(sharesText: String): String {
        val shares = sharesText.toDoubleOrNull() ?: return "0"
        val lots = shares / 100.0
        val rounded = String.format("%.2f", lots)
        return if (rounded.endsWith(".00")) rounded.dropLast(3) else rounded
    }

    /** 金额字符串格式化，优先按数值保留两位；异常时原样回退 */
    private fun formatMoneyText(value: String): String {
        val parsed = value.toDoubleOrNull() ?: return value
        return formatFixed2(parsed)
    }

    private fun formatPrice(value: Double): String = formatTrim(value)

    private fun fmtStr(value: String): String = value.toDoubleOrNull()?.let { formatTrim(it) } ?: value
}
