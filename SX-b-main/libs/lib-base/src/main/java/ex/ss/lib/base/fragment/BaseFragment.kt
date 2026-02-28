package ex.ss.lib.base.fragment

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.viewbinding.ViewBinding
import java.util.concurrent.atomic.AtomicBoolean

abstract class BaseFragment<VB : ViewBinding> : Fragment() {

    protected abstract val binding: VB

    private val initialized = AtomicBoolean(false)

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        if (initialized.compareAndSet(false, true)) {
            initialize()
        }
        initView()
        initData()
    }

    abstract fun initialize()

    abstract fun initView()

    abstract fun initData()


}
