package com.yanshu.app.ui.deal

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.TextView
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.AddStrategyRequest
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.data.SellRequest
import com.yanshu.app.data.SellStockRequest
import com.yanshu.app.databinding.ActivityBuyBinding
import com.yanshu.app.databinding.DialogTradeConfirmBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.repo.sina.SinaStockRepository
import com.yanshu.app.repo.eastmoney.SecIdResolver
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.entrust.EntrustListActivity
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.floor

/**
 * 股票账户交易页（买入 / 卖出）。
 * 买入：传 allcode + name + price。
 * 卖出：传 holdingItem（持仓记录）。
 */
class BuyActivity : BasicActivity<ActivityBuyBinding>() {

    override val binding: ActivityBuyBinding by viewBinding()

    companion object {
        private const val EXTRA_ALLCODE = "extra_allcode"
        private const val EXTRA_NAME = "extra_name"
        private const val EXTRA_PRICE = "extra_price"
        private const val EXTRA_IS_SELL = "extra_is_sell"
        private const val EXTRA_HOLDING_ID = "extra_holding_id"
        private const val EXTRA_HOLDING_LOTS = "extra_holding_lots"
        private const val EXTRA_HOLDING_BUY_PRICE = "extra_holding_buy_price"

        private const val TAG = "zs_ts"
        private const val DEFAULT_FEE_RATE = 0.0001

        fun startForBuy(context: Context, allcode: String, name: String = "", price: Double = 0.0) {
            context.startActivity(Intent(context, BuyActivity::class.java).apply {
                putExtra(EXTRA_ALLCODE, allcode)
                putExtra(EXTRA_NAME, name)
                putExtra(EXTRA_PRICE, price)
                putExtra(EXTRA_IS_SELL, false)
            })
        }

        fun startForSell(context: Context, item: HoldingItem) {
            context.startActivity(Intent(context, BuyActivity::class.java).apply {
                putExtra(EXTRA_ALLCODE, item.allcode)
                putExtra(EXTRA_NAME, item.title)
                putExtra(EXTRA_PRICE, item.cai_buy)
                putExtra(EXTRA_IS_SELL, true)
                putExtra(EXTRA_HOLDING_ID, item.id)
                putExtra(EXTRA_HOLDING_LOTS, item.canBuy.toIntOrNull() ?: 0)
                putExtra(EXTRA_HOLDING_BUY_PRICE, item.buyprice)
            })
        }

        /** Legacy entry point for buy from stock detail (keeps backward compat) */
        fun start(context: Context, allcode: String? = null, buyPrice: Double? = null) {
            startForBuy(context, allcode.orEmpty(), price = buyPrice ?: 0.0)
        }
    }

    private val sinaRepo = SinaStockRepository()
    private val pollHandler = Handler(Looper.getMainLooper())
    private var polling = false

    private var isSellMode = false

    // Common
    private var allcode: String = ""
    private var stockName: String = ""
    private var currentPrice: Double = 0.0
    private var lots: Int = 0              // 手数（1手=100股）

    // Buy mode
    private var tradePrice: Double = 0.0   // 委托价（可手动修改）
    private var userBalance: Double = 0.0
    private var buyFeeRate: Double = DEFAULT_FEE_RATE
    private var autoLotsApplied = false
    private var isEditBuyEnabled = true  // 后台控制买入价格是否可编辑

    // Sell mode
    private var holdingId: Int = 0
    private var holdingLots: Int = 0       // 持仓手数
    private var holdingBuyPrice: Double = 0.0
    private var sellFeeRate: Double = DEFAULT_FEE_RATE
    private var stampTaxRate: Double = 0.0003  // 印花税（卖出时收取）

    private val positionButtons get() = listOf(
        binding.btnPosition14,
        binding.btnPosition13,
        binding.btnPosition12,
        binding.btnPositionAll,
    )
    private val positionRatios = listOf(0.25, 1.0 / 3.0, 0.5, 1.0)

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!polling) return
            refreshMarket()
            pollHandler.postDelayed(this, 5_000L)
        }
    }

    override fun initView() {
        isSellMode = intent.getBooleanExtra(EXTRA_IS_SELL, false)
        allcode = intent.getStringExtra(EXTRA_ALLCODE).orEmpty()
        stockName = intent.getStringExtra(EXTRA_NAME).orEmpty()
        val intentPrice = intent.getDoubleExtra(EXTRA_PRICE, 0.0)
        if (intentPrice > 0) {
            currentPrice = intentPrice
            tradePrice = intentPrice
        }

        if (isSellMode) {
            holdingId = intent.getIntExtra(EXTRA_HOLDING_ID, 0)
            holdingLots = intent.getIntExtra(EXTRA_HOLDING_LOTS, 0)
            holdingBuyPrice = intent.getDoubleExtra(EXTRA_HOLDING_BUY_PRICE, 0.0)
            lots = holdingLots
        }
        autoLotsApplied = false

        setupClickListeners()
        updateModeUI()
        syncStockInfo()
        if (tradePrice > 0) binding.etTradePrice.setText(formatPrice(tradePrice))
    }

    override fun initData() {
        loadConfig()
        if (!isSellMode) {
            loadBalance()
            loadUserInfo()  // 获取 isEditBuy 配置
        } else {
            verifySellable()
        }
        refreshMarket()
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

    // ─── UI setup ───

    private fun updateModeUI() {
        val activeColor = android.graphics.Color.parseColor("#F44336")
        val inactiveColor = android.graphics.Color.parseColor("#999999")

        if (isSellMode) {
            binding.tabBuy.setTextColor(inactiveColor)
            binding.tabBuy.textStyle(bold = false)
            binding.tabSell.setTextColor(activeColor)
            binding.tabSell.textStyle(bold = true)
            moveTabIndicator(binding.tabSell)

            binding.tvTradePriceLabel.text = "卖出价格"
            binding.tvLotsLabel.text = "卖出手数"
            binding.tvTotalLabel.text = "总额(元)"
            binding.btnConfirm.text = "确认卖出"
            binding.btnConfirm.setBackgroundResource(R.drawable.bg_btn_primary)

            binding.layoutBuyPrice.visibility = View.VISIBLE
            binding.dividerBuyPrice.visibility = View.VISIBLE
            binding.layoutHoldingLots.visibility = View.VISIBLE
            binding.dividerHoldingLots.visibility = View.VISIBLE
            binding.layoutLimit.visibility = View.GONE
            binding.dividerLimit.visibility = View.GONE
            binding.layoutFee.visibility = View.VISIBLE
            binding.dividerFee.visibility = View.VISIBLE
            binding.layoutAvailableBalance.visibility = View.GONE
            binding.dividerAvailableBalance.visibility = View.GONE

            binding.tvBuyPriceValue.text = formatPrice(holdingBuyPrice)
            binding.tvHoldingLots.text = "$holdingLots"
        } else {
            binding.tabBuy.setTextColor(activeColor)
            binding.tabBuy.textStyle(bold = true)
            binding.tabSell.setTextColor(inactiveColor)
            binding.tabSell.textStyle(bold = false)
            moveTabIndicator(binding.tabBuy)

            binding.tvTradePriceLabel.text = "买入价格"
            binding.tvLotsLabel.text = "买入手数"
            binding.tvTotalLabel.text = "应付(元)"
            binding.btnConfirm.text = "买入下单"
            binding.btnConfirm.setBackgroundResource(R.drawable.bg_btn_primary)

            binding.layoutBuyPrice.visibility = View.GONE
            binding.dividerBuyPrice.visibility = View.GONE
            binding.layoutHoldingLots.visibility = View.GONE
            binding.dividerHoldingLots.visibility = View.GONE
            binding.layoutLimit.visibility = View.VISIBLE
            binding.dividerLimit.visibility = View.VISIBLE
            binding.layoutFee.visibility = View.VISIBLE
            binding.dividerFee.visibility = View.VISIBLE
            binding.layoutAvailableBalance.visibility = View.VISIBLE
            binding.dividerAvailableBalance.visibility = View.VISIBLE
            updateTradePriceEditability()
        }
    }

    private fun moveTabIndicator(anchorTab: TextView) {
        binding.tabIndicator.post {
            val params = binding.tabIndicator.layoutParams as androidx.constraintlayout.widget.ConstraintLayout.LayoutParams
            params.startToStart = anchorTab.id
            params.endToEnd = anchorTab.id
            binding.tabIndicator.layoutParams = params
        }
    }

    private fun TextView.textStyle(bold: Boolean) {
        typeface = if (bold) android.graphics.Typeface.DEFAULT_BOLD else android.graphics.Typeface.DEFAULT
        textSize = 16f
    }

    private fun syncStockInfo() {
        val codeDisplay = if (stockName.isNotBlank()) "$stockName[$allcode]" else allcode
        binding.tvStockInfo.text = codeDisplay
        if (currentPrice > 0) binding.tvCurrentPrice.text = formatPrice(currentPrice)
    }

    private fun setupClickListeners() {
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvTitle.text = "账户交易"

        binding.tabBuy.setOnClickListener {
            if (!isSellMode) return@setOnClickListener
            switchToBuyMode()
        }
        binding.tabSell.setOnClickListener {
            if (isSellMode) return@setOnClickListener
            switchToSellMode()
        }

        // Price stepper
        binding.etTradePrice.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
            override fun afterTextChanged(s: Editable?) {
                val v = s?.toString()?.toDoubleOrNull() ?: 0.0
                tradePrice = v
                recalculate()
                autoFillLotsIfNeeded()
            }
        })
        binding.btnPriceDecrease.setOnClickListener {
            val p = (tradePrice - 0.01).coerceAtLeast(0.01)
            tradePrice = Math.round(p * 100) / 100.0
            binding.etTradePrice.setText(formatPrice(tradePrice))
        }
        binding.btnPriceIncrease.setOnClickListener {
            val p = tradePrice + 0.01
            tradePrice = Math.round(p * 100) / 100.0
            binding.etTradePrice.setText(formatPrice(tradePrice))
        }

        // Lots stepper
        binding.btnDecrease.setOnClickListener {
            if (lots > 0) {
                lots--
                syncLotsDisplay()
                recalculate()
                autoLotsApplied = true
            }
        }
        binding.btnIncrease.setOnClickListener {
            val maxLots = if (isSellMode) holdingLots else calcMaxBuyLots()
            // maxLots=0 时（余额不足或为0），仍允许手动加手数，服务器校验
            if (maxLots <= 0 || lots < maxLots) {
                lots++
                syncLotsDisplay()
                recalculate()
                autoLotsApplied = true
            }
        }

        // Position ratio buttons
        positionButtons.forEachIndexed { index, btn ->
            btn.setOnClickListener {
                applyPositionRatio(positionRatios[index])
                highlightPositionButton(index)
                autoLotsApplied = true
            }
        }

        // Confirm
        binding.btnConfirm.setOnClickListener { showConfirmDialog() }
    }

    // ─── Tab switching ───

    private fun switchToBuyMode() {
        isSellMode = false
        holdingId = 0
        holdingLots = 0
        holdingBuyPrice = 0.0
        lots = 0
        autoLotsApplied = false
        syncLotsDisplay()
        updateModeUI()
        loadUserInfo()  // 切回买入模式时重新加载编辑权限
        loadBalance()
        loadConfig()
        recalculate()
        ensureTradePrice()
    }

    private fun switchToSellMode() {
        lifecycleScope.launch {
            val code = extractCode(allcode)
            val sellResp = ContractRemote.callApiSilent { getMrSellList(code) }
            val sellList = sellResp.data ?: emptyList()
            val target = allcode.lowercase()
            val sellItem = sellList.find { it.allcode.lowercase() == target }
            val sellableLots = sellItem?.canBuy?.toIntOrNull() ?: 0

            if (sellItem == null) {
                AppToast.show(this@BuyActivity, "暂无该股票持仓，无法卖出")
                return@launch
            }
            if (sellableLots <= 0) {
                AppToast.show(this@BuyActivity, "该股票暂不可卖出（T+N限制未到期）")
                return@launch
            }

            val resp = ContractRemote.callApiSilent {
                getDealHoldingList(page = 1, size = 100)
            }
            val list = resp.data?.list
            val item = list?.find { it.allcode.lowercase() == target }
            if (item == null) {
                AppToast.show(this@BuyActivity, "暂无该股票持仓，无法卖出")
                return@launch
            }

            isSellMode = true
            holdingId = item.id
            holdingLots = minOf(item.canBuy.toIntOrNull() ?: 0, sellableLots)
            holdingBuyPrice = item.buyprice
            lots = 0
            syncLotsDisplay()
            updateModeUI()
            loadConfig()
            recalculate()
        }
    }

    // ─── Data loading ───

    private fun verifySellable() {
        val code = extractCode(allcode)
        if (code.isBlank()) return
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getMrSellList(code) }
            val sellList = resp.data ?: emptyList()
            val target = allcode.lowercase()
            val match = sellList.find { it.allcode.lowercase() == target }
            if (match == null || (match.canBuy.toIntOrNull() ?: 0) <= 0) {
                AppToast.show(this@BuyActivity, "该股票暂不可卖出（T+N限制未到期）")
                binding.btnConfirm.isEnabled = false
                holdingLots = 0
                lots = 0
                syncLotsDisplay()
                recalculate()
            } else {
                val serverLots = match.canBuy.toIntOrNull() ?: 0
                if (serverLots < holdingLots) {
                    holdingLots = serverLots
                    binding.tvHoldingLots.text = "$holdingLots"
                }
                if (lots > holdingLots) {
                    lots = holdingLots
                    syncLotsDisplay()
                    recalculate()
                }
            }
        }
    }

    private fun loadConfig() {
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getConfig() }
            val config = resp.data ?: return@launch
            val buy = config.mai_fee.toDoubleOrNull()
            if (buy != null && buy > 0) buyFeeRate = buy
            val sell = config.maic_fee.toDoubleOrNull()
            if (sell != null && sell > 0) sellFeeRate = sell
            val tax = config.yh_fee.toDoubleOrNull()
            if (tax != null && tax > 0) stampTaxRate = tax

            if (isSellMode) {
                val feePct = String.format("%.2f", sellFeeRate * 100)
                val taxPct = String.format("%.2f", stampTaxRate * 100)
                binding.tvFeeLabel.text = "服务费${feePct}%+印花税${taxPct}%"
            } else {
                val pct = String.format("%.2f", buyFeeRate * 100)
                binding.tvFeeLabel.text = "服务费(元)${pct}%"
            }
            recalculate()
        }
    }

    /** 获取用户个人信息，读取 isEditBuy 字段控制买入价格编辑权限 */
    private fun loadUserInfo() {
        lifecycleScope.launch {
            try {
                val resp = ContractRemote.callApiSilent { getUserInfo() }
                val profile = resp.data?.list ?: return@launch
                isEditBuyEnabled = profile.isEditBuy != "0"
                Log.d(TAG, "loadUserInfo: isEditBuy=${profile.isEditBuy} => enabled=$isEditBuyEnabled")
                updateTradePriceEditability()
            } catch (e: Exception) {
                Log.e(TAG, "loadUserInfo error", e)
            }
        }
    }

    /** 根据 isEditBuy 控制买入价格输入框和加减按钮的可交互性 */
    private fun updateTradePriceEditability() {
        if (isSellMode) return  // 卖出模式不受限制
        val editable = isEditBuyEnabled
        binding.etTradePrice.isEnabled = editable
        binding.etTradePrice.isFocusable = editable
        binding.etTradePrice.isFocusableInTouchMode = editable
        binding.btnPriceDecrease.isEnabled = editable
        binding.btnPriceIncrease.isEnabled = editable
        binding.btnPriceDecrease.alpha = if (editable) 1.0f else 0.4f
        binding.btnPriceIncrease.alpha = if (editable) 1.0f else 0.4f
    }

    private fun loadBalance() {
        lifecycleScope.launch {
            try {
                val resp = ContractRemote.callApiSilent { getUserPrice_all1() }
                val item = resp.data?.list
                if (item == null) {
                    Log.w(TAG, "loadBalance: resp.data?.list is null, success=${resp.isSuccess()}")
                    return@launch
                }
                userBalance = item.balance - item.weituozj
                Log.d(TAG, "loadBalance: balance=${item.balance} weituozj=${item.weituozj} => userBalance=$userBalance")
                binding.tvAvailableBalance.text = formatMoney(userBalance)
                recalculate()
                autoFillLotsIfNeeded()
            } catch (e: Exception) {
                Log.e(TAG, "loadBalance error", e)
            }
        }
    }

    private fun refreshMarket() {
        if (allcode.isBlank()) return
        lifecycleScope.launch {
            try {
                val target = withContext(Dispatchers.IO) {
                    val code = extractCode(allcode)
                    val hint = extractMarketHint(allcode)
                    SecIdResolver.resolve(code, hint, false)
                }
                val snapshot = sinaRepo.fetchSnapshot(target)
                Log.d(TAG, "BuyActivity.refreshMarket snapshot=$snapshot")
                if (snapshot != null) {
                    val price = snapshot.price
                    if (price != null && price > 0) {
                        currentPrice = price
                        binding.tvCurrentPrice.text = formatPrice(price)
                        // 强制将买入价格同步为最新现价（除非用户正在手动编辑）
                        tradePrice = price
                        if (!binding.etTradePrice.hasFocus()) {
                            binding.etTradePrice.setText(formatPrice(price))
                        }
                        updateLimitPrices()
                        recalculate()
                        autoFillLotsIfNeeded()
                    }
                    val name = snapshot.name
                    if (!name.isNullOrBlank() && stockName.isBlank()) {
                        stockName = name
                        syncStockInfo()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "refreshMarket error", e)
            }
            ensureTradePrice()
        }
    }

    private fun updateLimitPrices() {
        val limitRate = if (isGrowthOrStar(allcode)) 0.20 else 0.10
        val limitUp = currentPrice * (1 + limitRate)
        val limitDown = currentPrice * (1 - limitRate)
        binding.tvLimitDown.text = "跌停: ${formatPrice(limitDown)}"
        binding.tvLimitUp.text = "涨停: ${formatPrice(limitUp)}"
    }

    private fun isGrowthOrStar(allcode: String): Boolean {
        val code = extractCode(allcode)
        return code.startsWith("30") || code.startsWith("68")
    }

    // ─── Calculation ───

    private fun applyPositionRatio(ratio: Double) {
        Log.d(TAG, "applyPositionRatio ratio=$ratio isSellMode=$isSellMode tradePrice=$tradePrice currentPrice=$currentPrice userBalance=$userBalance lots=$lots")
        if (isSellMode) {
            lots = floor(holdingLots * ratio).toInt().coerceAtLeast(if (holdingLots > 0) 1 else 0)
        } else {
            val effectivePrice = if (tradePrice > 0) tradePrice else currentPrice
            if (effectivePrice <= 0) {
                Log.w(TAG, "applyPositionRatio: price=0, tradePrice=$tradePrice currentPrice=$currentPrice")
                AppToast.show("价格未加载，请稍后再试")
                return
            }
            if (userBalance <= 0) {
                // 余额为0时，手数设为0，允许用户手动输入
                lots = 0
                Log.w(TAG, "applyPositionRatio: userBalance=$userBalance, setting lots=0")
                AppToast.show("可用余额不足，请手动输入买入手数")
                // 尝试重新加载余额（可能是接口延迟）
                loadBalance()
            } else {
                // 与H5端一致：按可用金额的比例计算能买多少手
                // 公式：可用金额 × 比例 ÷ (价格 × (1 + 手续费率) × 100)
                // 例如：63405 × 0.25 ÷ (10.87 × 1.0001 × 100) ≈ 14.58 → 向下取整 = 14手
                val costPerShare = effectivePrice * (1 + buyFeeRate)
                val availableForRatio = userBalance * ratio
                val calculatedLots = availableForRatio / costPerShare / 100
                // 向下取整，确保手数为整数，至少1手
                lots = floor(calculatedLots).toInt().coerceAtLeast(1)
                Log.d(TAG, "applyPositionRatio: userBalance=$userBalance ratio=$ratio availableForRatio=$availableForRatio price=$effectivePrice feeRate=$buyFeeRate costPerShare=$costPerShare calculatedLots=$calculatedLots => lots=$lots (整数)")
            }
        }
        syncLotsDisplay()
        recalculate()
    }

    private fun calcMaxBuyLots(overridePrice: Double = 0.0): Int {
        val effectivePrice = if (overridePrice > 0) overridePrice
            else if (tradePrice > 0) tradePrice
            else currentPrice
        if (effectivePrice <= 0 || userBalance <= 0) return 0
        val costPerShare = effectivePrice * (1 + buyFeeRate)
        return floor(userBalance / costPerShare / 100).toInt()
    }

    private fun syncLotsDisplay() {
        binding.tvLots.text = "$lots"
    }

    private fun recalculate() {
        val shares = lots * 100
        val price = if (tradePrice > 0) tradePrice else currentPrice
        val amount = shares * price

        if (isSellMode) {
            val sellFee = amount * sellFeeRate
            val stampTax = amount * stampTaxRate
            val totalDeductions = sellFee + stampTax
            val netAmount = amount - totalDeductions
            binding.tvFee.text = formatMoney(totalDeductions)
            binding.tvTotalAmount.text = formatMoney(netAmount)
        } else {
            val fee = amount * buyFeeRate
            val total = amount + fee
            binding.tvFee.text = formatMoney(fee)
            binding.tvTotalAmount.text = formatMoney(total)
        }
    }

    private fun autoFillLotsIfNeeded() {
        if (isSellMode || autoLotsApplied) return
        if (lots > 0) {
            autoLotsApplied = true
            return
        }
        val effectivePrice = if (tradePrice > 0) tradePrice else currentPrice
        if (effectivePrice <= 0) return  // 价格还没加载，等下次
        // 有余额则按余额算，否则默认填1手
        val maxLots = calcMaxBuyLots()
        lots = if (maxLots >= 1) 1 else if (effectivePrice > 0) 1 else 0
        Log.d(TAG, "autoFillLotsIfNeeded maxLots=$maxLots => lots=$lots tradePrice=$tradePrice currentPrice=$currentPrice userBalance=$userBalance")
        autoLotsApplied = true
        syncLotsDisplay()
        recalculate()
    }

    private fun ensureTradePrice() {
        if (isSellMode) return
        if (tradePrice > 0) return
        if (currentPrice > 0) {
            tradePrice = currentPrice
            if (!binding.etTradePrice.hasFocus()) {
                binding.etTradePrice.setText(formatPrice(tradePrice))
            }
            updateLimitPrices()
            recalculate()
            autoFillLotsIfNeeded()
            return
        }
    }

    private fun highlightPositionButton(selectedIndex: Int) {
        positionButtons.forEachIndexed { index, btn ->
            if (index == selectedIndex) {
                btn.setBackgroundResource(R.drawable.bg_position_button_selected)
                btn.setTextColor(getColor(android.R.color.white))
            } else {
                btn.setBackgroundResource(R.drawable.bg_position_button)
                btn.setTextColor(getColor(R.color.hq_stock_code_color))
            }
        }
    }

    // ─── Dialog ───

    private fun showConfirmDialog() {
        if (lots <= 0) {
            AppToast.show(if (isSellMode) "请输入卖出手数" else "请输入买入手数")
            return
        }
        val price = if (tradePrice > 0) tradePrice else currentPrice
        if (price <= 0) {
            AppToast.show("价格异常，请稍后重试")
            return
        }
        if (allcode.isBlank()) {
            AppToast.show("股票代码不能为空")
            return
        }
        if (isSellMode && holdingId == 0) {
            AppToast.show("持仓信息异常，请返回重试")
            return
        }
        if (!isSellMode && userBalance > 0) {
            val total = lots * 100 * price * (1 + buyFeeRate)
            if (total > userBalance) {
                AppToast.show("可用余额不足，最多可买${calcMaxBuyLots()}手")
                return
            }
        }

        val shares = lots * 100
        val amount = shares * price
        val total = if (isSellMode) {
            val deductions = amount * (sellFeeRate + stampTaxRate)
            amount - deductions
        } else {
            amount * (1 + buyFeeRate)
        }

        val dialog = Dialog(this)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        val db = DialogTradeConfirmBinding.inflate(layoutInflater)
        dialog.setContentView(db.root)

        db.tvDialogTitle.text = if (isSellMode) "确认卖出吗" else "确认买入吗"
        db.btnConfirmOk.text = if (isSellMode) "卖出" else "买入"
        db.btnConfirmOk.setBackgroundResource(R.drawable.bg_btn_primary)
        db.tvConfirmName.text = stockName.ifBlank { allcode }
        db.tvConfirmPrice.text = formatPrice(price)
        db.tvConfirmShares.text = "${shares}股"
        db.tvConfirmTotal.text = formatMoney(total)

        db.btnConfirmCancel.setOnClickListener { dialog.dismiss() }
        db.btnConfirmOk.setOnClickListener {
            dialog.dismiss()
            if (isSellMode) submitSell(price, shares) else submitBuy(price)
        }

        val window = dialog.window
        window?.setLayout(
            (resources.displayMetrics.widthPixels * 0.85).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
        )
        window?.setBackgroundDrawableResource(android.R.color.transparent)
        dialog.show()
    }

    private fun submitBuy(price: Double) {
        binding.btnConfirm.isEnabled = false
        lifecycleScope.launch {
            val resp = ContractRemote.callApi {
                addStrategy(AddStrategyRequest(allcode = allcode, buyprice = price, canBuy = lots))
            }
            binding.btnConfirm.isEnabled = true
            if (resp.isSuccess()) {
                AppToast.show(this@BuyActivity, "买入成功")
                EntrustListActivity.startAfterBuySuccess(this@BuyActivity)
                finish()
            }
        }
    }

    private fun submitSell(price: Double, shares: Int) {
        binding.btnConfirm.isEnabled = false
        lifecycleScope.launch {
            val primaryResp = ContractRemote.callApiSilent {
                sell(
                    SellRequest(
                        id = holdingId,
                        allcode = allcode,
                        canBuy = lots,
                        sellprice = price,
                    )
                )
            }
            val resp = if (!primaryResp.isSuccess() && isApiNotFound(primaryResp.failed.msg)) {
                ContractRemote.callApiSilent {
                    sellStockLegacy(SellStockRequest(id = holdingId, sellprice = price, number = shares))
                }
            } else {
                primaryResp
            }
            binding.btnConfirm.isEnabled = true
            if (resp.isSuccess()) {
                AppToast.show(this@BuyActivity, "卖出成功")
                finish()
            } else if (isApiNotFound(resp.failed.msg)) {
                AppToast.show(this@BuyActivity, "卖出接口未开放，请联系后端开通")
            } else {
                AppToast.show(this@BuyActivity, resp.failed.msg ?: "卖出失败，请重试")
            }
        }
    }

    private fun showErrorDialog(message: String) {
        AppDialog.show(supportFragmentManager) {
            title = "提示"
            content = message
            done = "确定"
        }
    }

    // ─── Polling ───

    private fun startPolling() {
        if (polling) return
        polling = true
        pollHandler.postDelayed(pollRunnable, 5_000L)
    }

    private fun stopPolling() {
        polling = false
        pollHandler.removeCallbacks(pollRunnable)
    }

    // ─── Utils ───

    private fun extractCode(allcode: String) =
        allcode.removePrefix("sh").removePrefix("sz").removePrefix("bj")

    private fun extractMarketHint(allcode: String) = when {
        allcode.startsWith("sh", ignoreCase = true) -> "sh"
        allcode.startsWith("sz", ignoreCase = true) -> "sz"
        allcode.startsWith("bj", ignoreCase = true) -> "bj"
        else -> ""
    }

    private fun isApiNotFound(msg: String?): Boolean {
        val text = msg ?: return false
        return text.contains("api不存在") || text.contains("api not found", ignoreCase = true)
    }

    private fun formatPrice(value: Double): String = String.format("%.2f", value)
    private fun formatMoney(value: Double): String = String.format("%.2f", value)
}
