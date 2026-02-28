package com.yanshu.app.ui.main

import android.util.Log
import android.graphics.Color
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.lifecycle.lifecycleScope
import com.proxy.base.ui.main.MainPageAdapter
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.config.UserConfig
import com.yanshu.app.databinding.ActivityMainBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.financial.FinancialFragment
import com.yanshu.app.ui.hq.HqFragment
import com.yanshu.app.ui.home.HomeFragment
import com.yanshu.app.ui.login.LoginActivity
import com.yanshu.app.ui.user.UserFragment
import com.yanshu.app.ui.trade.TradeFragment
import com.yanshu.app.util.TabWrapper
import com.yanshu.app.util.createTabItem
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : BasicActivity<ActivityMainBinding>() {

    companion object {
        private const val TAB_HOME = 0

        // 跳转到行情页面时需要选中的子Tab索引，-1表示不需要切换
        var pendingHqSubTab: Int = -1
    }

    override val binding: ActivityMainBinding by viewBinding()

    private var selectedMainTabIndex: Int = TAB_HOME

    override fun statusBarColor(): Int {
        return if (selectedMainTabIndex == TAB_HOME) {
            ContextCompat.getColor(this, R.color.user_red_primary)
        } else {
            Color.TRANSPARENT
        }
    }

    override fun useLightStatusBarIcons(): Boolean = selectedMainTabIndex != TAB_HOME
    
    /**
     * 跳转到行情页面并选中指定的子Tab
     * @param subTabIndex 子Tab索引: 0=行情, 1=新股申购, 2=战略配售, 3=天启护盘
     */
    fun navigateToHq(subTabIndex: Int) {
        pendingHqSubTab = subTabIndex
        TabWrapper.selectTab(1) // 切换到行情Tab
    }
    
    /**
     * 跳转到我的页面
     */
    fun navigateToMine() {
        TabWrapper.selectTab(4) // 切换到我的Tab
    }

    override fun initView() {
        val isLogin = UserConfig.isLogin()
        Log.d("sp_ts", "MainActivity initView isLogin=$isLogin")
        if (!isLogin) {
            Log.d("sp_ts", "MainActivity no token -> LoginActivity")
            startActivity(LoginActivity::class.java)
            finish()
            return
        }
        Log.d("sp_ts", "MainActivity calling getUserInfo()")
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getUserInfo() }
            val code = if (!resp.isSuccess()) resp.failed.code else -1
            Log.d("sp_ts", "MainActivity getUserInfo isSuccess=${resp.isSuccess()} code=$code")
            withContext(Dispatchers.Main) {
                if (isFinishing) return@withContext
                if (!resp.isSuccess()) {
                    Log.d("sp_ts", "MainActivity navigate -> LoginActivity")
                    UserConfig.logout()
                    Remote.resetLoginExpire()
                    startActivity(LoginActivity::class.java)
                    finish()
                    return@withContext
                }
                Log.d("sp_ts", "MainActivity setupViewPager + initTabs")
                setupViewPager()
                initTabs()
            }
        }
    }

    private fun setupViewPager() {
        Log.d("sp_ts", "MainActivity setupViewPager() creating adapter + fragments")
        // 仅预加载相邻页，减少未登录或 token 失效时同时触发的请求数
        binding.vpMain.offscreenPageLimit = 2
        binding.vpMain.adapter = MainPageAdapter(supportFragmentManager, lifecycle) {
            listOf(
                HomeFragment(),
                HqFragment(),
                TradeFragment(),
                FinancialFragment(),
                UserFragment()
            )
        }
        binding.vpMain.isUserInputEnabled = false
    }

    private fun initTabs() {
        // Tab 0: 首页
        TabWrapper.register(createTabItem(0, listOf(binding.linHome)) { isSelected ->
            if (isSelected) {
                binding.tvHome.setTextColor(
                    ContextCompat.getColor(this, R.color.text_selected_color)
                )
                binding.ivHome.setImageResource(R.drawable.tab_home_selected)
            } else {
                binding.tvHome.setTextColor(
                    ContextCompat.getColor(this, R.color.text_unselected_color)
                )
                binding.ivHome.setImageResource(R.drawable.tab_home_unselected)
            }
        })

        // Tab 1: 行情
        TabWrapper.register(createTabItem(1, listOf(binding.linHq)) { isSelected ->
            if (isSelected) {
                binding.tvHq.setTextColor(
                    ContextCompat.getColor(this, R.color.text_selected_color)
                )
                binding.ivHq.setImageResource(R.drawable.tab_hq_selected)
            } else {
                binding.tvHq.setTextColor(
                    ContextCompat.getColor(this, R.color.text_unselected_color)
                )
                binding.ivHq.setImageResource(R.drawable.tab_hq_unselected)
            }
        })

        // Tab 2: 交易
        TabWrapper.register(createTabItem(2, listOf(binding.linTrade)) { isSelected ->
            if (isSelected) {
                binding.tvTrade.setTextColor(
                    ContextCompat.getColor(this, R.color.text_selected_color)
                )
                binding.ivTrade.setImageResource(R.drawable.tab_trade_selected)
            } else {
                binding.tvTrade.setTextColor(
                    ContextCompat.getColor(this, R.color.text_unselected_color)
                )
                binding.ivTrade.setImageResource(R.drawable.tab_trade_unselected)
            }
        })

        // Tab 3: 自选
        TabWrapper.register(createTabItem(3, listOf(binding.linFinancial)) { isSelected ->
            if (isSelected) {
                binding.tvFinancial.setTextColor(
                    ContextCompat.getColor(this, R.color.text_selected_color)
                )
                binding.ivFinancial.setImageResource(R.drawable.tab_financial_selected)
            } else {
                binding.tvFinancial.setTextColor(
                    ContextCompat.getColor(this, R.color.text_unselected_color)
                )
                binding.ivFinancial.setImageResource(R.drawable.tab_financial_unselected)
            }
        })

        // Tab 4: 我的
        TabWrapper.register(createTabItem(4, listOf(binding.linMine)) { isSelected ->
            if (isSelected) {
                binding.tvMine.setTextColor(
                    ContextCompat.getColor(this, R.color.text_selected_color)
                )
                binding.ivMine.setImageResource(R.drawable.tab_mine_selected)
            } else {
                binding.tvMine.setTextColor(
                    ContextCompat.getColor(this, R.color.text_unselected_color)
                )
                binding.ivMine.setImageResource(R.drawable.tab_mine_unselected)
            }
        })

        TabWrapper.bindViewPager(binding.vpMain) { tabIndex ->
            applyStatusBarForMainTab(tabIndex)
        }
        TabWrapper.selectTab(0)
    }

    private fun applyStatusBarForMainTab(tabIndex: Int) {
        selectedMainTabIndex = tabIndex
        val insetsController = WindowCompat.getInsetsController(window, window.decorView)
        insetsController.isAppearanceLightStatusBars = useLightStatusBarIcons()
        window.statusBarColor = statusBarColor()
    }

    override fun initData() = Unit

    override fun onDestroy() {
        super.onDestroy()
        binding.vpMain.adapter = null
    }
}
