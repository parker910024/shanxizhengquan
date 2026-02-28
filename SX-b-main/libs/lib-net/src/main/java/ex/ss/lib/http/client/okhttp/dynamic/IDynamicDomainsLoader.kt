package ex.ss.lib.http.client.okhttp.dynamic

interface IDynamicDomainsLoader {
    suspend fun loadAllUrls(): List<String>
}