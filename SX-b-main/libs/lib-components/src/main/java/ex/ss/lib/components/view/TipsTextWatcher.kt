package ex.ss.lib.components.view


import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.text.TextUtils
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.widget.TextSwitcher
import android.widget.TextView
import androidx.core.content.ContextCompat
import ex.ss.lib.components.R
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

class TipsTextWatcher(context: Context?, attrs: AttributeSet?) : TextSwitcher(context, attrs) {

    private val mainScope by lazy { MainScope() }
    private val currentIndex = AtomicInteger(0)
    private val currentTurnJob = AtomicReference<Job>(null)

    private val onClickListener = mutableListOf<OnClickListener>()

    private val dp15 by lazy {
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 15F, resources.displayMetrics)
    }
    private val dp5 by lazy {
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 5F, resources.displayMetrics)
    }

    init {
        setInAnimation(context, R.anim.tip_switch_show)
        setOutAnimation(context, R.anim.tip_switch_hide)

        super.setOnClickListener {
            for (listener in onClickListener) {
                listener.onClick(it)
            }
        }
    }

    fun setConfig(
        drawStart: Int = 0,
        textSize: Float = 12F,
        textColor: Int = Color.BLACK,
        isSingleLine: Boolean = false,
    ) {
        setFactory {
            TextView(context).apply {
                setTextSize(TypedValue.COMPLEX_UNIT_SP, textSize)
                setSingleLine(isSingleLine)
                if (isSingleLine) {
                    ellipsize = TextUtils.TruncateAt.END
                }
                setTextColor(ColorStateList.valueOf(textColor))
                if (drawStart != 0) {
                    val drawable =
                        ContextCompat.getDrawable(this@TipsTextWatcher.context, drawStart)
                            ?.apply {
                                setBounds(0, 0, dp15.toInt(), dp15.toInt())
                            }
                    setCompoundDrawables(drawable, null, null, null)
                    compoundDrawablePadding = dp5.toInt()
                }
                gravity = Gravity.CENTER
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            }
        }
    }

    fun setList(list: List<String>, delay: Long = 5000) {
        if (list.isEmpty()) return
        currentIndex.set(0)
        setText(list[currentIndex.get()])
        currentTurnJob.get()?.cancel()
        val job = mainScope.launch {
            while (true) {
                delay(delay)
                if (currentIndex.get() + 1 >= list.size) {
                    currentIndex.set(0)
                } else {
                    currentIndex.addAndGet(1)
                }
                setText(list[currentIndex.get()])
            }
        }
        currentTurnJob.set(job)
    }


    override fun setOnClickListener(l: OnClickListener?) {
        l?.also { onClickListener.add(it) }
    }

    fun setOnItemClickListener(onItemClickListener: (Int) -> Unit) {
        setOnClickListener {
            val currentIndex = displayedChild
            onItemClickListener.invoke(currentIndex)
        }
    }

    fun onDestroy() {
        currentTurnJob.get()?.cancel()
    }

}