package ex.ss.lib.net.converter

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import ex.ss.lib.net.OnResponsePreCheck

import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Converter
import retrofit2.Retrofit
import java.lang.reflect.Type

class CompatibleGsonConvert(
    private val gson: Gson = Gson(),
    private val onResponsePreCheck: OnResponsePreCheck? = null
) : Converter.Factory() {
    override fun responseBodyConverter(
        type: Type,
        annotations: Array<out Annotation>,
        retrofit: Retrofit
    ): Converter<ResponseBody, *> {
        return if (type == String::class.java) {
            CompatibleGsonStringResponseBodyConverter()
        } else {
            val adapter = gson.getAdapter(TypeToken.get(type))
            CompatibleGsonResponseBodyConverter(gson, adapter, onResponsePreCheck)
        }
    }

    override fun requestBodyConverter(
        type: Type,
        parameterAnnotations: Array<out Annotation>,
        methodAnnotations: Array<out Annotation>,
        retrofit: Retrofit
    ): Converter<*, RequestBody> {
        val adapter = gson.getAdapter(TypeToken.get(type))
        return CompatibleGsonRequestBodyConverter(gson, adapter)
    }
}