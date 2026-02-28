package com.yanshu.app.ui.user

import android.content.Intent
import android.view.View
import androidx.constraintlayout.widget.ConstraintLayout
import com.yanshu.app.R
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.UserPriceAllItem
import com.yanshu.app.data.UserProfile
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.databinding.FragmentUserBinding
import com.yanshu.app.model.UserViewModel
import com.yanshu.app.ui.checkLogin
import com.yanshu.app.ui.bankcard.BankCardListActivity
import com.yanshu.app.ui.contract.ContractListActivity
import com.yanshu.app.ui.fund.FundRecordActivity
import com.yanshu.app.ui.message.MessageListActivity
import com.yanshu.app.ui.position.PositionRecordActivity
import com.yanshu.app.ui.password.ChangeLoginPwdActivity
import com.yanshu.app.ui.password.ChangeTradePwdActivity
import com.yanshu.app.ui.profile.ProfileActivity
import com.yanshu.app.ui.realname.RealNameActivity

import com.yanshu.app.ui.transfer.TransferInActivity
import com.yanshu.app.ui.transfer.TransferOutActivity
import com.yanshu.app.ui.ipo.MyIpoActivity
import com.yanshu.app.ui.placement.MyPlacementActivity
import com.yanshu.app.ui.hq.BulkTradeHoldingActivity
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import ex.ss.lib.base.fragment.BaseFragment
import kotlinx.coroutines.launch
import androidx.lifecycle.lifecycleScope

class UserFragment : BaseFragment<FragmentUserBinding>() {

    override val binding: FragmentUserBinding by viewBinding()

    private var isAssetsVisible = false
    private var lastUser: UserProfile? = null
    /** 资产数据来自 文档2.6 GET /api/user/getUserPrice_all */
    private var lastUserPrice: UserPriceAllItem? = null

    override fun initialize() {}

    override fun initView() {
        setupClickListeners()
        observeViewModel()
    }

    override fun initData() {
        android.util.Log.d("sp_ts", "UserFragment initData")
        if (UserConfig.isLogin()) {
            UserViewModel.userInfo()
            loadUserPriceAll()
        }
        loadConfigNames()
    }

    override fun onResume() {
        super.onResume()
        if (UserConfig.isLogin()) loadUserPriceAll()
    }

    private fun loadConfigNames() {
        viewLifecycleOwner.lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val config = response.data ?: return@launch
            val dzName = config.dz_syname.trim()
            if (dzName.isNotEmpty()) {
                binding.tvBlockTradeName.text = dzName
            }
        }
    }

    /** 文档 2.6 资产（个人中心）GET /api/user/getUserPrice_all */
    private fun loadUserPriceAll() {
        if (!UserConfig.isLogin()) return
        android.util.Log.d("sp_ts", "UserFragment loadUserPriceAll -> getUserPriceAll()")
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getUserPriceAll() }
            if (response.isSuccess()) {
                lastUserPrice = response.data?.list
                bindAssetViews()
            }
        }
    }

    private fun setupClickListeners() {
        binding.ivMessage.setOnClickListener {
            startActivity(Intent(requireContext(), MessageListActivity::class.java))
        }

        binding.ivSettings.setOnClickListener {
            ProfileActivity.start(requireContext())
        }

        binding.llTransferIn.setOnClickListener { TransferInActivity.start(requireContext()) }
        binding.llTransferOut.setOnClickListener { TransferOutActivity.start(requireContext()) }
        binding.llOnlineService.setOnClickListener { openCustomerService() }
        binding.llBankCard.setOnClickListener { BankCardListActivity.start(requireContext()) }
        binding.llLoginPwd.setOnClickListener { ChangeLoginPwdActivity.start(requireContext()) }
        binding.llTradePwd.setOnClickListener { ChangeTradePwdActivity.start(requireContext()) }
        binding.llCustomerService.setOnClickListener { openCustomerService() }
        binding.llLogout.setOnClickListener { showLogoutConfirmDialog() }

        binding.llPosition.setOnClickListener { PositionRecordActivity.start(requireContext()) }
        binding.llFundRecord.setOnClickListener { FundRecordActivity.start(requireContext()) }
        binding.llTradeRecord.setOnClickListener { PositionRecordActivity.start(requireContext(), initialTab = 1) }
        binding.llPositionRecord.setOnClickListener { PositionRecordActivity.start(requireContext()) }

        binding.llRealname.setOnClickListener {
            RealNameActivity.start(requireContext(), RealNameActivity.STATUS_NOT_VERIFIED)
        }

        binding.llProfile.setOnClickListener {
            ProfileActivity.start(requireContext())
        }

        binding.llContract.setOnClickListener {
            checkLogin {
                ContractListActivity.start(requireContext())
            }
        }

        binding.llIpoRecord.setOnClickListener { MyIpoActivity.start(requireContext()) }
        binding.llPlacementRecord.setOnClickListener { MyPlacementActivity.start(requireContext()) }
        binding.llBlockTrade.setOnClickListener { BulkTradeHoldingActivity.start(requireContext()) }

        binding.ivEye.setOnClickListener { toggleAssetsVisibility() }
    }

    private fun toggleAssetsVisibility() {
        isAssetsVisible = !isAssetsVisible
        bindAssetViews()
    }

    /** 资产区严格按文档 2.6 getUserPrice_all 的 list 绑定 */
    private fun bindAssetViews() {
        val price = lastUserPrice
        val hidden = "****"
        if (!isAssetsVisible || price == null) {
            val value = if (price == null) "0.00" else hidden
            binding.tvTotalAssets.text = value
            binding.tvAvailable.text = value
            binding.tvWithdrawable.text = value
            binding.tvStockPledge.text = value
            binding.tvMarketValue.text = value
            binding.tvTotalPnl.text = value
            binding.tvFloatingPnl.text = value
            return
        }
        binding.tvTotalAssets.text = formatMoney(price.property_money_total)
        binding.tvAvailable.text = formatMoney(price.balance)
        binding.tvWithdrawable.text = formatMoney(maxOf(0.0, price.balance - price.freeze_profit))
        binding.tvStockPledge.text = formatMoney(price.xingu_total)
        binding.tvMarketValue.text = formatMoney(price.city_value)
        binding.tvTotalPnl.text = formatMoney(price.totalyk)
        binding.tvFloatingPnl.text = formatMoney(price.fdyk)
    }

    private fun formatMoney(value: Double): String = "%.2f".format(value)

    /** 头部信息严格按文档 2.3 个人信息 api/stock/info 的 list 绑定 */
    private fun bindUserInfo(user: UserProfile?) {
        lastUser = user
        val isPhoneMode = AppConfigCenter.isPhoneRegisterMode
        updatePhoneVerticalAlignment()
        binding.tvAccount.visibility = View.VISIBLE
        if (user != null) {
            val phoneOrAccount = user.mobile.ifBlank { user.username }
            binding.tvPhone.text = if (isPhoneMode) maskPhone(phoneOrAccount) else phoneOrAccount
            binding.tvAccount.text =
                user.nickname.ifEmpty { user.username.ifEmpty { user.id.toString() } }
        } else {
            binding.tvPhone.text =
                if (isPhoneMode) getString(R.string.user_phone_placeholder)
                else getString(R.string.user_account_placeholder)
            binding.tvAccount.text = getString(R.string.user_account_placeholder)
        }
        bindAssetViews()
    }

    private fun updatePhoneVerticalAlignment() {
        val lp = binding.tvPhone.layoutParams as ConstraintLayout.LayoutParams
        lp.topToTop = R.id.iv_logo
        lp.bottomToTop = R.id.tv_account
        lp.bottomToBottom = ConstraintLayout.LayoutParams.UNSET
        binding.tvPhone.layoutParams = lp
    }

    private fun maskPhone(phone: String): String {
        if (phone.length < 8) return phone
        return phone.take(3) + "****" + phone.takeLast(4)
    }

    private fun observeViewModel() {
        UserViewModel.userInfoLiveData.observe(viewLifecycleOwner) { user ->
            bindUserInfo(user)
        }
    }

    private fun showLogoutConfirmDialog() {
        AppDialog.show(childFragmentManager) {
            title = getString(R.string.common_dialog_title)
            content = getString(R.string.logout_confirm_message)
            cancel = getString(R.string.common_cancel)
            done = getString(R.string.common_confirm)
            alwaysShow = true
            onDone = {
                activity?.let { UserConfig.performLogout(it) }
            }
        }
    }

    private fun openCustomerService() {
        CustomerServiceNavigator.open(requireActivity(), viewLifecycleOwner.lifecycleScope)
    }
}
