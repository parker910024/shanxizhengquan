package ex.ss.lib.components.view

import androidx.recyclerview.widget.RecyclerView

fun RecyclerView.onScrollEnd(call: () -> Unit) {
    addOnScrollListener(object : RecyclerView.OnScrollListener() {
        override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
            if (!recyclerView.canScrollVertically(1)) {
                call.invoke()
            }
        }
    })
}