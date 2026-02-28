package ex.ss.lib.net

import ex.ss.lib.net.bean.ResponseData

abstract class BaseRemoteRepository<API> {

    abstract val apiClass: Class<API>

    protected val api by lazy { SSNet.create(apiClass) }

    /**
     * 网络请求
     */
    protected suspend fun <T> call(call: suspend () -> T): ResponseData<T> {
        return runCatching {
            val data = call()
            ResponseData.success(data)
        }.getOrElse {
            ResponseData.failed(it)
        }
    }
}