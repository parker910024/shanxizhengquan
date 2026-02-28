package ex.ss.lib.http.client.okhttp.dynamic

import ex.ss.lib.http.request.SSHttpRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl
import okhttp3.Response
import java.util.concurrent.atomic.AtomicBoolean

object DynamicDomainsClient : IDynamicDomainClient {

    private const val DYNAMIC_DOMAINS = "dynamic-domains"

    private val initialized by lazy { AtomicBoolean(false) }

    private val dynamicDomains by lazy { LinkedHashMap<String, String>() }

    override suspend fun initialize(loader: IDynamicDomainsLoader) = withContext(Dispatchers.IO) {
        val urls = loader.loadAllUrls()
        if (urls.isNotEmpty()) {
            urls.onEach { dynamicDomains[getDynamicDomainKey(it)] = it }
        }
        initialized.set(true)
    }

    override suspend fun <Response> buildRequest(request: SSHttpRequest<Response>): SSHttpRequest<Response> {
        if (request.path.startsWith("http")) return request
        val domains = request.getHeaders(DYNAMIC_DOMAINS).toMutableList()
        val dynamicDomain = getNextDynamicDomain(domains) ?: return request
        domains.add(getDynamicDomainKey(dynamicDomain))
        return request.newBuilder()
            .domain(dynamicDomain)
            .addHeaders(DYNAMIC_DOMAINS, domains)
            .rebuild()
    }

    override suspend fun <Response> canRetryDynamicDomain(request: SSHttpRequest<Response>): Boolean {
        if (request.path.startsWith("http")) return false
        return getNextDynamicDomain(request.getHeaders(DYNAMIC_DOMAINS)) != null
    }

    private fun getNextDynamicDomain(domains: List<String>): String? {
        if (dynamicDomains.isEmpty()) return null
        for (entry in dynamicDomains) {
            if (domains.contains(entry.key)) continue
            return entry.value
        }
        return null
    }

    private fun getDynamicDomainKey(domain: String): String {
        return "${domain.hashCode()}"
    }

    override fun isInitialized() = initialized.get()

}
