package ex.ss.lib.net.converter

import com.google.gson.Gson
import com.google.gson.JsonIOException
import com.google.gson.TypeAdapter
import com.google.gson.stream.JsonToken
import ex.ss.lib.net.OnResponsePreCheck
import okhttp3.ResponseBody
import retrofit2.Converter
import java.io.InputStreamReader

class CompatibleGsonResponseBodyConverter<T>(
    private val gson: Gson,
    private val adapter: TypeAdapter<T>,
    private val onResponsePreCheck: OnResponsePreCheck?
) :
    Converter<ResponseBody, T> {

    override fun convert(value: ResponseBody): T {
        value.use {
            val json = it.string()
            val preCheck = onResponsePreCheck?.invoke(gson, json) ?: (true to json)
            val response = if (preCheck.first) json else preCheck.second
            val charset = it.contentType()?.charset() ?: Charsets.UTF_8
            val jsonReader =
                gson.newJsonReader(InputStreamReader(response.byteInputStream(charset)))
            val result = adapter.read(jsonReader)
            if (jsonReader.peek() != JsonToken.END_DOCUMENT) {
                throw JsonIOException("JSON document was not fully consumed.")
            }
            return result
        }
    }

}