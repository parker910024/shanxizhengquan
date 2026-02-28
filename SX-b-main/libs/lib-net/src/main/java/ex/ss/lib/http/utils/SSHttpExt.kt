package ex.ss.lib.http.utils

import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull


fun HttpUrl.replaceBaseUrl(newBaseUrl: HttpUrl?, baseUrl: HttpUrl): HttpUrl {
    if (newBaseUrl == null) return this
    val builder = newBuilder()

    pathSegments.onEach { builder.removePathSegment(0) } //remove new builder all pathSegment

    builder.scheme(newBaseUrl.scheme) //replace new scheme
    builder.host(newBaseUrl.host) //replace new host
    builder.port(newBaseUrl.port)//replace new port

    newBaseUrl.pathSegments.filter { item -> item.isNotEmpty() }.onEach { path ->
        builder.addPathSegment(path)
    }//add newBaseUrl pathSegments to new builder

    pathSegments.filter { path ->
        !baseUrl.pathSegments.contains(path)
    }.filter { item -> item.isNotEmpty() }.onEach { path ->
        builder.addPathSegment(path)
    }//filter api path add to new builder pathSegments

    return builder.build()
}

fun String.isHttpUrl(): Boolean {
    return toHttpUrlOrNull()?.scheme == "http"
}

fun String.isHttpsUrl(): Boolean {
    return toHttpUrlOrNull()?.scheme == "https"
}