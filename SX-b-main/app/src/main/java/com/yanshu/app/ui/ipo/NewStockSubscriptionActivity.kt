package com.yanshu.app.ui.ipo

import android.content.Context
import android.content.Intent
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.IPOGroup
import com.yanshu.app.databinding.ActivityNewStockSubscriptionBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.hq.IpoDetailActivity
import com.yanshu.app.ui.hq.adapter.IpoAdapter
import com.yanshu.app.ui.hq.model.IpoData
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NewStockSubscriptionActivity : BasicActivity<ActivityNewStockSubscriptionBinding>() {

    override val binding: ActivityNewStockSubscriptionBinding by viewBinding()

    private lateinit var ipoAdapter: IpoAdapter

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, NewStockSubscriptionActivity::class.java))
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }
        binding.tvRecords.setOnClickListener { MyIpoActivity.start(this) }

        val dateFormat = SimpleDateFormat("yyyy-MM-dd E", Locale.CHINESE)
        binding.tvDate.text = dateFormat.format(Date())

        ipoAdapter = IpoAdapter()
        binding.rvIpoList.adapter = ipoAdapter
        ipoAdapter.setOnItemClick { data, _ ->
            IpoDetailActivity.start(
                context = this,
                name = data.name,
                code = data.code,
                market = data.market,
                issuePrice = data.issuePrice,
                peRatio = data.peRatio,
                board = data.board,
                fxNum = data.fxNum,
                wsfxNum = data.wsfxNum,
                sgLimit = data.sgLimit,
                sgDate = data.sgDate,
                ssDate = data.ssDate,
                zqRate = data.zqRate,
                industry = data.industry,
            )
        }
    }

    override fun initData() {
        loadIpoList()
    }

    private fun loadIpoList() {
        binding.progressLoading.visibility = View.VISIBLE
        binding.tvEmpty.visibility = View.GONE
        binding.rvIpoList.visibility = View.GONE

        lifecycleScope.launch {
            val result = runCatching {
                Remote.callApi { getIpoList(page = 1, type = 0) }
            }.getOrNull()
            val groups: List<IPOGroup> = result?.data?.list ?: emptyList()

            val ipoList = groups.flatMap { group ->
                group.sub_info.map { item ->
                    IpoData(
                        name = item.name,
                        code = item.code,
                        market = item.getMarketTag(),
                        issuePrice = item.fx_price.toDoubleOrNull() ?: 0.0,
                        peRatio = item.fx_rate.toDoubleOrNull() ?: 0.0,
                        board = item.getMarketTag(),
                        fxNum = item.fx_num,
                        wsfxNum = item.wsfx_num,
                        sgLimit = item.sg_limit,
                        sgDate = item.sg_date,
                        ssDate = item.ss_date,
                        zqRate = item.zq_rate,
                        industry = item.industry,
                    )
                }
            }

            binding.progressLoading.visibility = View.GONE
            if (ipoList.isEmpty()) {
                binding.tvEmpty.visibility = View.VISIBLE
                binding.rvIpoList.visibility = View.GONE
            } else {
                binding.tvEmpty.visibility = View.GONE
                binding.rvIpoList.visibility = View.VISIBLE
                ipoAdapter.submitList(ipoList)
            }
        }
    }
}
