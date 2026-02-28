package ex.ss.lib.http.bean

data class ResponseSuccess<T>(val code: Int = 0, val msg: String = "", val data: T) {
    companion object {
        fun <T> create(code: Int, msg: String, data: T): ResponseSuccess<T> {
            return ResponseSuccess(code, msg, data)
        }
    }
}
