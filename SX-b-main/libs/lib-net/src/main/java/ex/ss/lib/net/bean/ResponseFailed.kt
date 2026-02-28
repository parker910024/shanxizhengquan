package ex.ss.lib.net.bean

data class ResponseFailed(val code: Int = 0, val msg: String? = null, val e: Throwable? = null) {
    companion object {
        fun create(code: Int, msg: String?): ResponseFailed {
            return ResponseFailed(code, msg)
        }

        fun create(throwable: Throwable): ResponseFailed {
            return ResponseFailed(-1, "${throwable.message}", throwable)
        }
    }
}
