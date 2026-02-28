package ex.ss.lib.base.extension

import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

fun FragmentActivity.toast(textResId: Int) {
    lifecycleScope.launch(Dispatchers.Main) {
        toast(resources.getString(textResId))
    }
}

fun FragmentActivity.toast(text: String) {
    lifecycleScope.launch(Dispatchers.Main) {
        Toast.makeText(this@toast, text, Toast.LENGTH_SHORT).show()
    }
}

fun Fragment.toast(textResId: Int) {
    viewLifecycleOwner.lifecycleScope.launch(Dispatchers.Main) {
        toast(resources.getString(textResId))
    }
}

fun Fragment.toast(text: String) {
    viewLifecycleOwner.lifecycleScope.launch(Dispatchers.Main) {
        Toast.makeText(requireContext(), text, Toast.LENGTH_SHORT).show()
    }
}
