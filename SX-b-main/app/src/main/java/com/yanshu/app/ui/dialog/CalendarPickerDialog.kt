package com.yanshu.app.ui.dialog

import android.app.Dialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentManager
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.yanshu.app.R
import com.yanshu.app.databinding.DialogCalendarPickerBinding
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * 日历选择底部弹窗
 */
class CalendarPickerDialog : BottomSheetDialogFragment() {

    private var _binding: DialogCalendarPickerBinding? = null
    private val binding get() = _binding!!

    private var selectedDate: Calendar = Calendar.getInstance()
    private var maxDate: Calendar = Calendar.getInstance()
    private var onDateSelected: ((Date) -> Unit)? = null

    private lateinit var monthAdapter: MonthAdapter
    private val months = mutableListOf<MonthData>()

    companion object {
        private const val ARG_SELECTED_DATE = "selected_date"
        private const val ARG_MAX_DATE = "max_date"

        fun show(
            fragmentManager: FragmentManager,
            selectedDate: Date,
            maxDate: Date,
            onDateSelected: (Date) -> Unit
        ) {
            val dialog = CalendarPickerDialog().apply {
                arguments = Bundle().apply {
                    putLong(ARG_SELECTED_DATE, selectedDate.time)
                    putLong(ARG_MAX_DATE, maxDate.time)
                }
                this.onDateSelected = onDateSelected
            }
            dialog.show(fragmentManager, "CalendarPickerDialog")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            selectedDate.timeInMillis = it.getLong(ARG_SELECTED_DATE)
            maxDate.timeInMillis = it.getLong(ARG_MAX_DATE)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = DialogCalendarPickerBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val dialog = super.onCreateDialog(savedInstanceState) as BottomSheetDialog
        dialog.setOnShowListener {
            val bottomSheet = dialog.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            bottomSheet?.let {
                val behavior = BottomSheetBehavior.from(it)
                behavior.state = BottomSheetBehavior.STATE_EXPANDED
                behavior.skipCollapsed = true
            }
        }
        return dialog
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupViews()
        generateMonths()
        setupRecyclerView()
        scrollToSelectedMonth()
    }

    private fun setupViews() {
        binding.ivClose.setOnClickListener { dismiss() }
        
        binding.btnConfirm.setOnClickListener {
            onDateSelected?.invoke(selectedDate.time)
            dismiss()
        }

        updateYearMonthTitle()
    }

    private fun updateYearMonthTitle() {
        val format = SimpleDateFormat("yyyy年M月", Locale.getDefault())
        binding.tvYearMonth.text = format.format(selectedDate.time)
    }

    private fun generateMonths() {
        months.clear()
        
        // 生成从1年前到今天的月份数据
        val startCalendar = Calendar.getInstance().apply {
            add(Calendar.YEAR, -1)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        
        val endCalendar = Calendar.getInstance()
        
        while (startCalendar.before(endCalendar) || isSameMonth(startCalendar, endCalendar)) {
            val year = startCalendar.get(Calendar.YEAR)
            val month = startCalendar.get(Calendar.MONTH)
            months.add(MonthData(year, month, generateDaysForMonth(year, month)))
            startCalendar.add(Calendar.MONTH, 1)
        }
    }

    private fun isSameMonth(cal1: Calendar, cal2: Calendar): Boolean {
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.MONTH) == cal2.get(Calendar.MONTH)
    }

    private fun generateDaysForMonth(year: Int, month: Int): List<DayData> {
        val days = mutableListOf<DayData>()
        val calendar = Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month)
            set(Calendar.DAY_OF_MONTH, 1)
        }

        // 获取该月第一天是星期几 (1=周日, 2=周一, ..., 7=周六)
        // 转换为周一为第一天的索引 (0=周一, ..., 6=周日)
        val firstDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        val offset = if (firstDayOfWeek == Calendar.SUNDAY) 6 else firstDayOfWeek - 2

        // 添加空白占位
        repeat(offset) {
            days.add(DayData(0, false, false, false))
        }

        // 添加该月的每一天
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        for (day in 1..daysInMonth) {
            calendar.set(Calendar.DAY_OF_MONTH, day)
            val isSelected = isSameDay(calendar, selectedDate)
            val isToday = isSameDay(calendar, Calendar.getInstance())
            val isFuture = calendar.after(maxDate)
            days.add(DayData(day, isSelected, isToday, isFuture))
        }

        return days
    }

    private fun isSameDay(cal1: Calendar, cal2: Calendar): Boolean {
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }

    private fun setupRecyclerView() {
        monthAdapter = MonthAdapter(months, selectedDate, maxDate) { year, month, day ->
            // 检查是否超过最大日期
            val clickedDate = Calendar.getInstance().apply {
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month)
                set(Calendar.DAY_OF_MONTH, day)
            }
            
            if (clickedDate.after(maxDate)) {
                AppToast.show("已经是最后一天了")
                return@MonthAdapter
            }

            selectedDate.set(Calendar.YEAR, year)
            selectedDate.set(Calendar.MONTH, month)
            selectedDate.set(Calendar.DAY_OF_MONTH, day)
            
            updateYearMonthTitle()
            refreshCalendar()
        }

        binding.rvCalendar.layoutManager = LinearLayoutManager(requireContext())
        binding.rvCalendar.adapter = monthAdapter

        // 监听滚动以更新标题
        binding.rvCalendar.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                super.onScrolled(recyclerView, dx, dy)
                val layoutManager = recyclerView.layoutManager as LinearLayoutManager
                val firstVisiblePosition = layoutManager.findFirstVisibleItemPosition()
                if (firstVisiblePosition >= 0 && firstVisiblePosition < months.size) {
                    val monthData = months[firstVisiblePosition]
                    val format = SimpleDateFormat("yyyy年M月", Locale.getDefault())
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, monthData.year)
                        set(Calendar.MONTH, monthData.month)
                    }
                    binding.tvYearMonth.text = format.format(cal.time)
                }
            }
        })
    }

    private fun scrollToSelectedMonth() {
        val targetIndex = months.indexOfFirst {
            it.year == selectedDate.get(Calendar.YEAR) &&
                    it.month == selectedDate.get(Calendar.MONTH)
        }
        if (targetIndex >= 0) {
            binding.rvCalendar.scrollToPosition(targetIndex)
        }
    }

    private fun refreshCalendar() {
        // 重新生成月份数据
        months.forEachIndexed { index, monthData ->
            months[index] = monthData.copy(
                days = generateDaysForMonth(monthData.year, monthData.month)
            )
        }
        monthAdapter.notifyDataSetChanged()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}

/**
 * 月份数据
 */
data class MonthData(
    val year: Int,
    val month: Int,
    val days: List<DayData>
)

/**
 * 日期数据
 */
data class DayData(
    val day: Int,          // 0 表示占位
    val isSelected: Boolean,
    val isToday: Boolean,
    val isFuture: Boolean  // 是否是未来日期（不可选）
)

/**
 * 月份适配器
 */
class MonthAdapter(
    private val months: List<MonthData>,
    private val selectedDate: Calendar,
    private val maxDate: Calendar,
    private val onDayClick: (year: Int, month: Int, day: Int) -> Unit
) : RecyclerView.Adapter<MonthAdapter.MonthViewHolder>() {

    class MonthViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvMonthTitle: TextView = itemView.findViewById(R.id.tv_month_title)
        val rvDays: RecyclerView = itemView.findViewById(R.id.rv_days)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MonthViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_calendar_month, parent, false)
        return MonthViewHolder(view)
    }

    override fun onBindViewHolder(holder: MonthViewHolder, position: Int) {
        val monthData = months[position]
        val format = SimpleDateFormat("yyyy年M月", Locale.getDefault())
        val cal = Calendar.getInstance().apply {
            set(Calendar.YEAR, monthData.year)
            set(Calendar.MONTH, monthData.month)
        }
        holder.tvMonthTitle.text = format.format(cal.time)

        holder.rvDays.layoutManager = GridLayoutManager(holder.itemView.context, 7)
        holder.rvDays.adapter = DayAdapter(monthData.days) { day ->
            if (day > 0) {
                onDayClick(monthData.year, monthData.month, day)
            }
        }
    }

    override fun getItemCount() = months.size
}

/**
 * 日期适配器
 */
class DayAdapter(
    private val days: List<DayData>,
    private val onDayClick: (day: Int) -> Unit
) : RecyclerView.Adapter<DayAdapter.DayViewHolder>() {

    class DayViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvDay: TextView = itemView.findViewById(R.id.tv_day)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DayViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_calendar_day, parent, false)
        return DayViewHolder(view)
    }

    override fun onBindViewHolder(holder: DayViewHolder, position: Int) {
        val dayData = days[position]
        val context = holder.itemView.context

        if (dayData.day == 0) {
            holder.tvDay.text = ""
            holder.tvDay.background = null
            holder.itemView.setOnClickListener(null)
        } else {
            holder.tvDay.text = dayData.day.toString()
            
            when {
                dayData.isSelected -> {
                    holder.tvDay.setBackgroundResource(R.drawable.bg_calendar_selected)
                    holder.tvDay.setTextColor(ContextCompat.getColor(context, R.color.white))
                }
                dayData.isFuture -> {
                    holder.tvDay.background = null
                    holder.tvDay.setTextColor(ContextCompat.getColor(context, R.color.text_second_color))
                }
                else -> {
                    holder.tvDay.background = null
                    holder.tvDay.setTextColor(ContextCompat.getColor(context, R.color.black))
                }
            }

            holder.itemView.setOnClickListener {
                if (!dayData.isFuture) {
                    onDayClick(dayData.day)
                }
            }
        }
    }

    override fun getItemCount() = days.size
}
