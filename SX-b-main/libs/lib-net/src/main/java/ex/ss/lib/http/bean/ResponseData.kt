package ex.ss.lib.http.bean

data class ResponseData<T>(private val status: STATUS, private val item: Any?) {
    enum class STATUS {
        SUCCESS, FAILED
    }

    companion object {
        fun <T> success(item: T): ResponseData<T> {
            return ResponseData(STATUS.SUCCESS, ResponseSuccess.create(200, "", item))
        }

        fun <T> success(code: Int, msg: String, item: T): ResponseData<T> {
            return ResponseData(STATUS.SUCCESS, ResponseSuccess.create(code, msg, item))
        }

        fun <T> failed(code: Int, msg: String?): ResponseData<T> {
            return ResponseData(STATUS.FAILED, ResponseFailed.create(code, msg))
        }

        fun <T> failed(e: Throwable): ResponseData<T> {
            return ResponseData(STATUS.FAILED, ResponseFailed.create(e))
        }

        fun <T> failed(failed: ResponseFailed): ResponseData<T> {
            return ResponseData(STATUS.FAILED, failed)
        }
    }

    suspend fun onSuccess(call: suspend (T) -> Unit): ResponseData<T> {
        if (status == STATUS.SUCCESS && item is ResponseSuccess<*>) {
            call.invoke(item.data as T)
        }
        return this
    }

    suspend fun onFailed(call: suspend (ResponseFailed) -> Unit): ResponseData<T> {
        if (status == STATUS.FAILED && item is ResponseFailed) {
            call.invoke(item)
        }
        return this
    }

    fun isSuccess(): Boolean {
        return status == STATUS.SUCCESS
    }

    fun isFailed(): Boolean {
        return status == STATUS.FAILED
    }

    val data: T
        get() {
            if (status == STATUS.SUCCESS && item != null && item is ResponseSuccess<*>) return item.data as T
            else throw throw Exception("Unknown Error!!!")
        }

    val success: ResponseSuccess<T>
        get() {
            return if (status == STATUS.SUCCESS && item is ResponseSuccess<*>) item as ResponseSuccess<T>
            else throw Exception("Unknown Error!!!")
        }

    val failed: ResponseFailed
        get() {
            return if (status == STATUS.FAILED && item is ResponseFailed) item
            else throw Exception("Unknown Error!!!")
        }
}


