package com.yanshu.app.ui.transfer

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.data.RechargeRequest
import com.yanshu.app.databinding.ActivityTransferInDetailBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.repo.contract.ContractServiceFactory
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.web.SimpleWebActivity
import com.yanshu.app.util.BrowserUtils
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import retrofit2.HttpException

/**
 * 閾惰瘉杞叆璇︽儏椤碉細
 * 1) 鍔犺浇閫氶亾璇︽儏 /api/index/getyhkconfignew
 * 2) 鏍￠獙閲戦
 * 3) 鎻愪氦 /api/user/recharge
 */
class TransferInDetailActivity : BasicActivity<ActivityTransferInDetailBinding>() {

    companion object {
        private const val EXTRA_CHANNEL_ID = "channel_id"
        private const val EXTRA_MINLOW = "minlow"
        private const val EXTRA_MAXHIGH = "maxhigh"
        private const val EXTRA_TDNAME = "tdname"
        private const val EXTRA_URL_TYPE = "url_type"

        fun start(context: Context, channelId: Int, minlow: Int, maxhigh: Int, tdname: String, urlType: Int = 2) {
            context.startActivity(Intent(context, TransferInDetailActivity::class.java).apply {
                putExtra(EXTRA_CHANNEL_ID, channelId)
                putExtra(EXTRA_MINLOW, minlow)
                putExtra(EXTRA_MAXHIGH, maxhigh)
                putExtra(EXTRA_TDNAME, tdname)
                putExtra(EXTRA_URL_TYPE, urlType)
            })
        }
    }

    override val binding: ActivityTransferInDetailBinding by viewBinding()

    private var channelId = 0
    private var minlow = 100
    private var maxhigh = 100000
    private var tdname = ""
    private var urlType = 2

    // account 閰嶇疆涓彧鍖呭惈姝ｆ暟鏃朵粎鍏佽鍥哄畾閲戦锛涘寘鍚?0 鏃跺厑璁歌嚜瀹氫箟閲戦
    private var supportCustomAmount = true
    private var fixedAmounts: List<Int> = emptyList()

    override fun initView() {
        channelId = intent.getIntExtra(EXTRA_CHANNEL_ID, 0)
        minlow = intent.getIntExtra(EXTRA_MINLOW, 100)
        maxhigh = intent.getIntExtra(EXTRA_MAXHIGH, 100000)
        tdname = intent.getStringExtra(EXTRA_TDNAME) ?: ""
        urlType = intent.getIntExtra(EXTRA_URL_TYPE, 2)

        binding.titleBar.tvTitle.text = tdname.ifEmpty { "银证转入" }
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE

        binding.tvAmountRangeHint.isVisible = false
        updateAmountHints()

        binding.etAmount.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val amount = s.toString().toDoubleOrNull()
                binding.btnTransferIn.isEnabled = amount != null && amount > 0
            }
        })

        binding.btnTransferIn.setOnClickListener { onConfirmClick() }
    }

    override fun initData() {
        loadChannelConfig()
    }

    private fun loadChannelConfig() {
        lifecycleScope.launch {
            val configRes = ContractRemote.callApiSilent { getYhkConfigNew(channelId) }
            val data = configRes.data

            data.charge_low.toDoubleOrNull()?.toInt()?.let { chargeLow ->
                if (chargeLow > 0) minlow = chargeLow
            }

            val channel = data.list?.firstOrNull()
            if (channel != null) {
                if (channel.minlow > 0) minlow = channel.minlow
                if (channel.maxhigh > 0) maxhigh = channel.maxhigh
                applyAmountConfig(channel.account)
            }

            updateAmountHints()
        }
    }

    private fun applyAmountConfig(accountConfig: String) {
        if (accountConfig.isBlank()) {
            supportCustomAmount = true
            fixedAmounts = emptyList()
            setAmountInputEditable(true)
            binding.layoutFixedAmounts.isVisible = false
            return
        }

        val parsed = accountConfig
            .split(",")
            .mapNotNull { it.trim().toIntOrNull() }
            .distinct()

        if (parsed.isEmpty()) {
            supportCustomAmount = true
            fixedAmounts = emptyList()
            setAmountInputEditable(true)
            binding.layoutFixedAmounts.isVisible = false
            return
        }

        supportCustomAmount = parsed.contains(0)
        fixedAmounts = parsed.filter { it > 0 }

        if (fixedAmounts.isNotEmpty()) {
            // 鏄剧ず鍥哄畾閲戦閫夋嫨鎸夐挳
            binding.layoutFixedAmounts.isVisible = true
            buildFixedAmountButtons()

            if (!supportCustomAmount) {
                // 不允许自定义金额：隐藏输入框，自动选中第一个
                binding.layoutAmount.isVisible = false
                binding.dividerAmount.isVisible = false
                selectFixedAmount(fixedAmounts.first())
            } else {
                setAmountInputEditable(true)
            }
        }
    }

    /**
     * 鍔ㄦ€佺敓鎴愬浐瀹氶噾棰濋€夋嫨鎸夐挳
     */
    private fun buildFixedAmountButtons() {
        binding.llAmountButtons.removeAllViews()

        for (amount in fixedAmounts) {
            val btn = TextView(this).apply {
                text = amount.toString()
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                gravity = Gravity.CENTER
                setPadding(dp(16), dp(12), dp(16), dp(12))
                setTextColor(Color.parseColor("#333333"))
                background = createAmountBtnBg(false)

                val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                lp.marginEnd = dp(10)
                layoutParams = lp

                setOnClickListener { selectFixedAmount(amount) }
            }
            binding.llAmountButtons.addView(btn)
        }
    }

    /**
     * 閫変腑鏌愪釜鍥哄畾閲戦
     */
    private fun selectFixedAmount(amount: Int) {
        binding.etAmount.setText(amount.toString())

        // 鏇存柊鎸夐挳閫変腑鏍峰紡
        for (i in 0 until binding.llAmountButtons.childCount) {
            val child = binding.llAmountButtons.getChildAt(i) as? TextView ?: continue
            val isSelected = child.text.toString().toIntOrNull() == amount
            child.background = createAmountBtnBg(isSelected)
            child.setTextColor(
                if (isSelected) Color.WHITE else Color.parseColor("#333333")
            )
        }

        binding.btnTransferIn.isEnabled = true
    }

    private fun createAmountBtnBg(selected: Boolean): GradientDrawable {
        return GradientDrawable().apply {
            cornerRadius = dp(6).toFloat()
            if (selected) {
                setColor(Color.parseColor("#E85D5D"))  // 选中红色，匹配确认按钮风格
            } else {
                setColor(Color.parseColor("#F5F5F5"))
                setStroke(1, Color.parseColor("#DDDDDD"))
            }
        }
    }

    private fun setAmountInputEditable(editable: Boolean) {
        binding.etAmount.isEnabled = editable
        binding.etAmount.isFocusable = editable
        binding.etAmount.isFocusableInTouchMode = editable
        binding.etAmount.isClickable = editable
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun updateAmountHints() {
        binding.tvAmountRangeHint.text = "转入金额范围：$minlow - $maxhigh 元"
        binding.tvMinHint.text = "最小转入金额为 $minlow 元"
    }

    private fun onConfirmClick() {
        val input = binding.etAmount.text.toString().trim()
        val amount = input.toDoubleOrNull()

        when {
            amount == null || amount <= 0 -> {
                AppToast.show("请输入有效金额")
                return
            }
            amount < minlow -> {
                AppToast.show("最小转入金额为 $minlow 元")
                return
            }
            amount > maxhigh -> {
                AppToast.show("最大转入金额为 $maxhigh 元")
                return
            }
            !supportCustomAmount && fixedAmounts.isNotEmpty() && amount.toInt() !in fixedAmounts -> {
                AppToast.show("请选择通道允许的固定金额")
                return
            }
        }

        doRecharge(amount ?: return)
    }

    private fun doRecharge(amount: Double) {
        binding.btnTransferIn.isEnabled = false
        lifecycleScope.launch {
            try {
                val resp = ContractServiceFactory.api.recharge(
                    RechargeRequest(
                        money = formatMoneyForApi(amount),
                        sysbankid = channelId,
                    )
                )
                if (resp.retCode == 0) {
                    val jumpUrl = resp.payJumpUrl.orEmpty().trim()
                    if (jumpUrl.isNotEmpty()) {
                        if (urlType == 1) {
                            SimpleWebActivity.start(this@TransferInDetailActivity, tdname.ifEmpty { "支付" }, jumpUrl)
                        } else {
                            BrowserUtils.openBrowser(this@TransferInDetailActivity, jumpUrl)
                        }
                    } else {
                        AppToast.show(resp.retMsg.ifEmpty { "转入申请已提交" })
                    }
                    finish()
                } else if (resp.retCode == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                    Remote.notifyLoginExpireOnce()
                    binding.btnTransferIn.isEnabled = true
                } else {
                    AppToast.show(resp.retMsg.ifEmpty { "转入失败，请重试" })
                    binding.btnTransferIn.isEnabled = true
                }
            } catch (e: Exception) {
                if ((e as? HttpException)?.code() == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                    Remote.notifyLoginExpireOnce()
                } else {
                    AppToast.show(e.message ?: "网络异常，请重试")
                }
                binding.btnTransferIn.isEnabled = true
            }
        }
    }

    private fun formatMoneyForApi(amount: Double): String {
        val longValue = amount.toLong()
        return if (amount == longValue.toDouble()) longValue.toString() else amount.toString()
    }
}
