package ex.ss.lib.http.client.okhttp.dynamic.bean

import okhttp3.HttpUrl

data class DynamicDomainsConfig(
    private val all: LinkedHashMap<HttpUrl, Int> = LinkedHashMap()
) {

    fun set(list: List<HttpUrl>) = synchronized(all) {
        all.clear()
        list.onEach { all[it] = 0 }
    }

    fun snap(): List<HttpUrl> = synchronized(all) {
        return all.map { it.value to it.key }.sortedByDescending { it.first }.map { it.second }
    }

    fun increase(httpUrl: HttpUrl) = synchronized(all) {
        all[httpUrl] = (all[httpUrl] ?: 0) + 1
    }

    fun isEmpty(): Boolean {
        return all.isEmpty()
    }
}
