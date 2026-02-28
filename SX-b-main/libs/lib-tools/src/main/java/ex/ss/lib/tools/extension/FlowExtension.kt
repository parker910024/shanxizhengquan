package ex.ss.lib.tools.extension

import android.os.Bundle
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch


fun <T> Flow<T>.collectWithOwner(owner: LifecycleOwner, action: suspend (value: T) -> Unit) =
    owner.lifecycleScope.launch {
        collectLatest(action)
    }

fun <T> Flow<T?>.collectWithOwnerNotNull(
    owner: LifecycleOwner, action: suspend (value: T) -> Unit
) = owner.lifecycleScope.launch {
    collectLatest { data ->
        data?.also {
            action.invoke(it)
        }
    }
}


fun <T> Flow<T>.collectThis(activity: FragmentActivity) {
    collectWithOwner(activity) {}
}

fun <T> Flow<T>.collectThis(fragment: Fragment) {
    collectWithOwner(fragment.viewLifecycleOwner) {}
}