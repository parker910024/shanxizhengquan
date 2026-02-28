package com.yanshu.app.ui.trade

import android.content.Intent
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.UserPriceAll1Item
import com.yanshu.app.databinding.FragmentTradeBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.bankcard.BankCardListActivity
import com.yanshu.app.ui.deal.CancelOrderActivity
import com.yanshu.app.ui.dragon.DragonActivity
import com.yanshu.app.ui.entrust.EntrustListActivity
import com.yanshu.app.ui.fund.FundRecordActivity
import com.yanshu.app.ui.password.ChangeTradePwdActivity
import com.yanshu.app.ui.position.PositionRecordActivity
import com.yanshu.app.ui.record.TradeRecordActivity
import com.yanshu.app.ui.transfer.TransferInActivity
import com.yanshu.app.ui.transfer.TransferOutActivity
import com.yanshu.app.ui.main.MainActivity
import com.yanshu.app.ui.message.MessageListActivity
import ex.ss.lib.base.extension.viewBinding
import ex.ss.lib.base.fragment.BaseFragment
import kotlinx.coroutines.launch

class TradeFragment : BaseFragment<FragmentTradeBinding>() {

    override val binding: FragmentTradeBinding by viewBinding()

    private var isAssetsVisible = false
    private var lastUserPrice: UserPriceAll1Item? = null

    override fun initialize() {
    }

    override fun initView() {
        setupMenuItems()
        setupFunctionCards()
        binding.ivEyeHide.setOnClickListener { toggleAssetsVisibility() }
    }
    
    private fun setupFunctionCards() {
        // 买入 -> 先搜索选股，再进入买入页
        binding.llBuy.setOnClickListener {
            com.yanshu.app.ui.search.StockSearchActivity.startForBuy(requireContext())
        }
        // 卖出 -> 文档无接口，暂跳持仓（可选卖出入口）
        binding.llSell.setOnClickListener {
            PositionRecordActivity.start(requireContext())
        }
        // 查询 -> 搜索股票页面
        binding.llQuery.setOnClickListener {
            com.yanshu.app.ui.search.StockSearchActivity.start(requireContext())
        }
        // 持仓 -> 持仓记录
        binding.llPosition.setOnClickListener {
            PositionRecordActivity.start(requireContext())
        }
        // 撤单 -> 撤单页
        binding.llCancel.setOnClickListener {
            CancelOrderActivity.start(requireContext())
        }
        // 委托 -> 委托列表
        binding.llOrder.setOnClickListener {
            EntrustListActivity.start(requireContext())
        }
        // 成交 -> 交易记录
        binding.llDeal.setOnClickListener {
            TradeRecordActivity.start(requireContext())
        }
        // 对账单 -> 资金记录
        binding.llStatement.setOnClickListener {
            FundRecordActivity.start(requireContext())
        }
        // 资金记录 -> 资产区右侧
        binding.llFundRecord.setOnClickListener {
            FundRecordActivity.start(requireContext())
        }
        // 银证转账（网格内）-> 我的
        binding.llBankTransfer.setOnClickListener {
            TransferInActivity.start(requireContext())
        }
        binding.llBankTransferAction.setOnClickListener {
            (activity as? MainActivity)?.navigateToMine()
        }
        // 更多 -> 我的
        binding.llMore.setOnClickListener {
            (activity as? MainActivity)?.navigateToMine()
        }
        
        // 新股新债 -> 跳转到行情页面的新股申购Tab
        binding.clNewStock.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(1) // 1 = 新股申购
        }
        
        // 场外撮合 -> 跳转到行情页面的天启护盘Tab
        binding.clOtc.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(3) // 3 = 天启护盘
        }
        
        // 国债逆回购 - 暂无点击业务
        // binding.clTreasury.setOnClickListener { }
        
        // 智汇现金理财 - 暂无点击业务
        // binding.clWealth.setOnClickListener { }
    }

    override fun initData() {
        android.util.Log.d("sp_ts", "TradeFragment initData")
        updateAccountNumber()
        if (UserConfig.isLogin()) loadAsset()
        binding.ivRefresh.setOnClickListener { if (UserConfig.isLogin()) loadAsset() }
    }

    private fun updateAccountNumber() {
        binding.tvAccountNumber.text = UserConfig.getUser()?.nickname.orEmpty()
    }

    private fun loadAsset() {
        if (!UserConfig.isLogin()) return
        android.util.Log.d("sp_ts", "TradeFragment loadAsset -> getUserPrice_all1()")
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getUserPrice_all1() }
            val item = resp.data?.list ?: return@launch
            lastUserPrice = item
            bindAssetViews()
        }
    }

    private fun toggleAssetsVisibility() {
        isAssetsVisible = !isAssetsVisible
        binding.ivEyeHide.setImageResource(
            if (isAssetsVisible) R.drawable.ic_trade_eye_show else R.drawable.ic_trade_eye_hide
        )
        bindAssetViews()
    }

    private fun bindAssetViews() {
        val item = lastUserPrice
        val hidden = "****"

        if (!isAssetsVisible || item == null) {
            val value = if (item == null) "0.00" else hidden
            binding.tvHoldingValue.text = value
            binding.tvTodayPnl.text = if (item == null) "累计盈亏+0.00" else "累计盈亏$hidden"
            binding.tvHoldingPnl.text = if (item == null) "持仓盈亏+0.00" else "持仓盈亏$hidden"
            binding.tvAccountAssetValue.text = value
            binding.tvAvailableValue.text = value
            return
        }

        // 持仓市值应使用持仓市值字段，避免无持仓时显示账户总资产
        binding.tvHoldingValue.text = formatMoney(item.city_value)
        val totalykSign = if (item.totalyk >= 0) "+" else ""
        binding.tvTodayPnl.text = "累计盈亏${totalykSign}${formatMoney(item.totalyk)}"
        val fdykSign = if (item.fdyk >= 0) "+" else ""
        binding.tvHoldingPnl.text = "持仓盈亏${fdykSign}${formatMoney(item.fdyk)}"
        binding.tvAccountAssetValue.text = formatMoney(item.property_money_total)
        binding.tvAvailableValue.text = formatMoney(item.balance)
    }

    private fun formatMoney(value: Double): String = String.format("%.2f", value)
    
    private fun setupMenuItems() {
        // 科创板 -> 跳转到行情页面
        binding.menuSciTech.ivIcon.setImageResource(R.drawable.ic_menu_sci_tech)
        binding.menuSciTech.tvTitle.text = getString(R.string.trade_menu_sci_tech)
        binding.menuSciTech.root.setOnClickListener {
            (activity as? MainActivity)?.navigateToHq(0) // 0 = 行情
        }
        
        // 龙虎榜
        binding.menuDragon.ivIcon.setImageResource(R.drawable.ic_menu_dragon)
        binding.menuDragon.tvTitle.text = getString(R.string.trade_menu_dragon)
        binding.menuDragon.root.setOnClickListener {
            startActivity(Intent(requireContext(), DragonActivity::class.java))
        }
        
        // 消息通知
        binding.menuNotification.ivIcon.setImageResource(R.drawable.ic_menu_notification)
        binding.menuNotification.tvTitle.text = getString(R.string.trade_menu_notification)
        binding.menuNotification.root.setOnClickListener {
            startActivity(Intent(requireContext(), MessageListActivity::class.java))
        }
        
        // 修改交易密码
        binding.menuChangePwd.ivIcon.setImageResource(R.drawable.ic_menu_password)
        binding.menuChangePwd.tvTitle.text = getString(R.string.trade_menu_change_pwd)
        binding.menuChangePwd.root.setOnClickListener {
            startActivity(Intent(requireContext(), ChangeTradePwdActivity::class.java))
        }
        
        // 银行卡管理
        binding.menuBankCard.ivIcon.setImageResource(R.drawable.ic_menu_bank_card)
        binding.menuBankCard.tvTitle.text = getString(R.string.trade_menu_bank_card)
        binding.menuBankCard.root.setOnClickListener {
            BankCardListActivity.start(requireContext())
        }
        
        // 银证转出
        binding.menuTransferOut.ivIcon.setImageResource(R.drawable.ic_menu_transfer_out)
        binding.menuTransferOut.tvTitle.text = getString(R.string.trade_menu_transfer_out)
        binding.menuTransferOut.root.setOnClickListener {
            TransferOutActivity.start(requireContext())
        }
        
        // 更多功能 -> 跳转到我的页面
        binding.menuMoreFunc.ivIcon.setImageResource(R.drawable.ic_menu_more_func)
        binding.menuMoreFunc.tvTitle.text = getString(R.string.trade_menu_more)
        binding.menuMoreFunc.root.setOnClickListener {
            (activity as? MainActivity)?.navigateToMine()
        }
    }

    override fun onResume() {
        super.onResume()
    }

    override fun onDestroyView() {
        super.onDestroyView()
    }
}
