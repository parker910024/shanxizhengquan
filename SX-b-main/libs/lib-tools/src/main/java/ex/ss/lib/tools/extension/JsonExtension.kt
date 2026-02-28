package ex.ss.lib.tools.extension

import android.os.Bundle
import androidx.core.os.bundleOf
import com.google.gson.Gson


object JsonExtension {

    const val KEY_ANY_BUNDLE = "any.to.bundle"

    val gson by lazy { Gson() }

    inline fun <reified T> toBundle(data: T?): Bundle = runCatching {
        data ?: return bundleOf()
        val json = gson.toJson(data)
        return bundleOf(KEY_ANY_BUNDLE to json)
    }.getOrElse { bundleOf() }

    inline fun <reified T> fromBundle(data: Bundle?): T? {
        val json = data?.getString(KEY_ANY_BUNDLE, null) ?: return null
        return runCatching { gson.fromJson(json, T::class.java) }.getOrNull()
    }

}

inline fun <reified T> T.toBundle(): Bundle {
    return JsonExtension.toBundle(this)
}

inline fun <reified T> Class<T>.fromBundle(bundle: Bundle?): T? {
    return JsonExtension.fromBundle(bundle)
}