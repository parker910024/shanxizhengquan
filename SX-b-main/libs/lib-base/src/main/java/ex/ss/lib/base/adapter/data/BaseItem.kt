package ex.ss.lib.base.adapter.data

interface BaseItem {
    fun <T : BaseItem> areContentsTheSame(other: T): Boolean {
        return equals(other)
    }
}