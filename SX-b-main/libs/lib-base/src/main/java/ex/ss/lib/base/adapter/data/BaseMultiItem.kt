package ex.ss.lib.base.adapter.data

interface BaseMultiItem {
    fun <T : BaseMultiItem> areContentsTheSame(other: T): Boolean {
        return equals(other)
    }
}