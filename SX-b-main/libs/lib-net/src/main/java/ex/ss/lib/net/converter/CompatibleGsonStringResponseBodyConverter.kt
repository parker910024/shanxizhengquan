package ex.ss.lib.net.converter

import okhttp3.ResponseBody
import retrofit2.Converter

class CompatibleGsonStringResponseBodyConverter : Converter<ResponseBody, String> {

    override fun convert(value: ResponseBody): String {
        value.use {
            return it.string()
        }
    }

}