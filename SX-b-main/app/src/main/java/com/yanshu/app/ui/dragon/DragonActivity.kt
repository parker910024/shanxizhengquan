package com.yanshu.app.ui.dragon

import android.content.res.ColorStateList
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityDragonBinding
import com.yanshu.app.repo.EastMoneyDragonRepository
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dialog.CalendarPickerDialog
import com.yanshu.app.ui.hq.detail.StockDetailActivity
import ex.ss.lib.base.adapter.data.BaseItem
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class DragonActivity : BasicActivity<ActivityDragonBinding>() {

    override val binding: ActivityDragonBinding by viewBinding()

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private val today = Calendar.getInstance()
    private var currentDate = Calendar.getInstance()
    private lateinit var adapter: DragonAdapter

    override fun initView() {
        setupTitleBar()
        setupRecyclerView()
        setupDatePicker()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = "龙虎榜"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun setupRecyclerView() {
        adapter = DragonAdapter { item ->
            StockDetailActivity.start(
                context = this,
                code = item.code,
                name = item.name,
                marketHint = item.market,
                isIndex = false,
            )
        }
        binding.rvDragonList.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)
        binding.rvDragonList.adapter = adapter
    }

    private fun setupDatePicker() {
        binding.btnPrevDate.setOnClickListener {
            currentDate.add(Calendar.DAY_OF_YEAR, -1)
            updateDateUI()
            loadData()
        }
        binding.btnNextDate.setOnClickListener {
            currentDate.add(Calendar.DAY_OF_YEAR, 1)
            updateDateUI()
            loadData()
        }
        binding.ivCalendar.setOnClickListener {
            showDatePickerDialog()
        }
        updateDateUI()
    }

    private fun updateDateUI() {
        binding.tvDate.text = dateFormat.format(currentDate.time)
        val isToday = dateFormat.format(currentDate.time) == dateFormat.format(today.time)
        binding.btnNextDate.isEnabled = !isToday
        binding.btnNextDate.alpha = if (isToday) 0.3f else 1f
    }

    private fun showDatePickerDialog() {
        CalendarPickerDialog.show(
            fragmentManager = supportFragmentManager,
            selectedDate = currentDate.time,
            maxDate = today.time,
            onDateSelected = { date ->
                currentDate.time = date
                updateDateUI()
                loadData()
            }
        )
    }

    override fun initData() {
        loadData()
    }

    private fun loadData() {
        val dateStr = dateFormat.format(currentDate.time)
        adapter.submitList(emptyList())
        binding.progressDragon.visibility = View.VISIBLE
        binding.tvEmpty.visibility = View.GONE
        binding.rvDragonList.visibility = View.GONE

        lifecycleScope.launch {
            val result = EastMoneyDragonRepository.getListByDate(dateStr)
            binding.progressDragon.visibility = View.GONE

            result.fold(
                onSuccess = { list ->
                    if (list.isEmpty()) {
                        binding.tvEmpty.visibility = View.VISIBLE
                        binding.rvDragonList.visibility = View.GONE
                        binding.tvEmpty.text = getString(R.string.dragon_empty)
                    } else {
                        binding.rvDragonList.visibility = View.VISIBLE
                        binding.tvEmpty.visibility = View.GONE
                        adapter.submitList(list)
                    }
                },
                onFailure = {
                    binding.tvEmpty.visibility = View.VISIBLE
                    binding.rvDragonList.visibility = View.GONE
                    binding.tvEmpty.text = getString(R.string.dragon_load_fail)
                    AppToast.show(getString(R.string.dragon_load_fail))
                }
            )
        }
    }
}

/**
 * 龙虎榜数据项
 */
data class DragonItem(
    val name: String,
    val code: String,
    val closePrice: Double,
    val netBuy: Double,
    val changePct: Double,
    val isUp: Boolean,
    val market: String? = null,
    val tradeDate: String? = null  // 用于按日过滤，格式 "yyyy-MM-dd 00:00:00"
) : BaseItem
