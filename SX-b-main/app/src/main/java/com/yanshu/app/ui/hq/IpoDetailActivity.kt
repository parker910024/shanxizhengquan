package com.yanshu.app.ui.hq

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.drawable.GradientDrawable
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.SubscribeIpoRequest
import com.yanshu.app.databinding.ActivityIpoDetailBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dialog.IpoSubscribeDialog
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class IpoDetailActivity : BasicActivity<ActivityIpoDetailBinding>() {

    companion object {
        private const val EXTRA_NAME = "extra_name"
        private const val EXTRA_CODE = "extra_code"
        private const val EXTRA_MARKET = "extra_market"
        private const val EXTRA_ISSUE_PRICE = "extra_issue_price"
        private const val EXTRA_PE_RATIO = "extra_pe_ratio"
        private const val EXTRA_BOARD = "extra_board"
        private const val EXTRA_FX_NUM = "extra_fx_num"
        private const val EXTRA_WSFX_NUM = "extra_wsfx_num"
        private const val EXTRA_SG_LIMIT = "extra_sg_limit"
        private const val EXTRA_SG_DATE = "extra_sg_date"
        private const val EXTRA_SS_DATE = "extra_ss_date"
        private const val EXTRA_ZQ_RATE = "extra_zq_rate"
        private const val EXTRA_INDUSTRY = "extra_industry"

        fun start(
            context: Context,
            name: String,
            code: String,
            market: String,
            issuePrice: Double,
            peRatio: Double,
            board: String,
            fxNum: String = "0",
            wsfxNum: String = "0",
            sgLimit: String = "0",
            sgDate: String = "",
            ssDate: String = "",
            zqRate: String = "0",
            industry: String = "",
        ) {
            val intent = Intent(context, IpoDetailActivity::class.java).apply {
                putExtra(EXTRA_NAME, name)
                putExtra(EXTRA_CODE, code)
                putExtra(EXTRA_MARKET, market)
                putExtra(EXTRA_ISSUE_PRICE, issuePrice)
                putExtra(EXTRA_PE_RATIO, peRatio)
                putExtra(EXTRA_BOARD, board)
                putExtra(EXTRA_FX_NUM, fxNum)
                putExtra(EXTRA_WSFX_NUM, wsfxNum)
                putExtra(EXTRA_SG_LIMIT, sgLimit)
                putExtra(EXTRA_SG_DATE, sgDate)
                putExtra(EXTRA_SS_DATE, ssDate)
                putExtra(EXTRA_ZQ_RATE, zqRate)
                putExtra(EXTRA_INDUSTRY, industry)
            }
            context.startActivity(intent)
        }
    }

    private val stockName by lazy { intent.getStringExtra(EXTRA_NAME) ?: "" }
    private val stockCode by lazy { intent.getStringExtra(EXTRA_CODE) ?: "" }
    private val market by lazy { intent.getStringExtra(EXTRA_MARKET) ?: "" }
    private val issuePrice by lazy { intent.getDoubleExtra(EXTRA_ISSUE_PRICE, 0.0) }
    private val peRatio by lazy { intent.getDoubleExtra(EXTRA_PE_RATIO, 0.0) }
    private val board by lazy { intent.getStringExtra(EXTRA_BOARD) ?: "" }
    private val fxNum by lazy { intent.getStringExtra(EXTRA_FX_NUM) ?: "0" }
    private val wsfxNum by lazy { intent.getStringExtra(EXTRA_WSFX_NUM) ?: "0" }
    private val sgLimit by lazy { intent.getStringExtra(EXTRA_SG_LIMIT) ?: "0" }
    private val sgDate by lazy { intent.getStringExtra(EXTRA_SG_DATE) ?: "" }
    private val ssDate by lazy { intent.getStringExtra(EXTRA_SS_DATE) ?: "" }
    private val zqRate by lazy { intent.getStringExtra(EXTRA_ZQ_RATE) ?: "0" }
    private val industry by lazy { intent.getStringExtra(EXTRA_INDUSTRY) ?: "" }

    override val binding: ActivityIpoDetailBinding by viewBinding()

    override fun initView() {
        setupTitleBar()
        setupContent()
        setupButton()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = stockName
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun setupContent() {
        binding.tvStockName.text = stockName
        binding.tvStockCode.text = stockCode

        val (tagText, tagColor) = getMarketTagInfo(market)
        binding.tvMarketTag.text = tagText
        (binding.tvMarketTag.background as? GradientDrawable)?.setColor(tagColor)

        binding.tvApplyCode.text = stockCode
        binding.tvPeRatio.text = if (peRatio > 0) String.format("%.2f%%", peRatio) else "--"

        binding.tvBoard.text = if (industry.isNotBlank()) industry else board
        binding.tvBoard.setTextColor(getBoardColor(board))

        binding.tvIssuePrice.text = String.format("%.2f", issuePrice)
        binding.tvIssueAmount.text = formatStockCount(fxNum)
        binding.tvOnlineAmount.text = formatStockCount(wsfxNum)
    }

    private fun formatStockCount(raw: String): String {
        val v = raw.toLongOrNull() ?: return raw
        return when {
            v >= 10_000L -> String.format("%.4f", v / 10_000.0)
            else -> v.toString()
        }
    }

    private fun setupButton() {
        binding.btnSubscribe.setOnClickListener {
            IpoSubscribeDialog.show(supportFragmentManager) {
                onConfirm = {
                    doSubscribe()
                }
            }
        }
    }

    private fun doSubscribe() {
        if (stockCode.isBlank()) {
            AppToast.show("股票代码不能为空")
            return
        }
        binding.btnSubscribe.isEnabled = false
        binding.btnSubscribe.text = "申购中..."
        lifecycleScope.launch {
            val response = ContractRemote.callApi {
                subscribeIpo(SubscribeIpoRequest(code = stockCode))
            }
            if (response.isSuccess()) {
                AppDialog.show(supportFragmentManager) {
                    title = "提示"
                    content = "申购成功"
                    done = "确定"
                    onDone = { finish() }
                }
            } else {
                binding.btnSubscribe.isEnabled = true
                binding.btnSubscribe.text = "一键申购"
                val msg = response.failed.msg
                if (msg.isNullOrBlank()) {
                    AppToast.show("申购失败，请稍后重试")
                }
            }
        }
    }

    private fun getMarketTagInfo(market: String): Pair<String, Int> {
        return when (market) {
            "北交" -> "北" to 0xFF3B82F6.toInt()
            "科创" -> "科" to 0xFFF97316.toInt()
            "沪" -> "沪" to 0xFFEF4444.toInt()
            "深" -> "深" to 0xFF3B82F6.toInt()
            else -> market.take(1) to 0xFF6B7280.toInt()
        }
    }

    private fun getBoardColor(board: String): Int {
        return when (board) {
            "北交" -> 0xFF3B82F6.toInt()
            "科创" -> 0xFFF97316.toInt()
            "沪" -> 0xFFEF4444.toInt()
            "深" -> 0xFF3B82F6.toInt()
            else -> 0xFF6B7280.toInt()
        }
    }

    override fun initData() {
    }
}
