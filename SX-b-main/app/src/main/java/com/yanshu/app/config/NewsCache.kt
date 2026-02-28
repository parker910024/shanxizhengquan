package com.yanshu.app.config

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.yanshu.app.data.ApiNewsItem
import com.yanshu.app.repo.Remote
import ex.ss.lib.components.mmkv.IMMKVDelegate
import ex.ss.lib.components.mmkv.kvDelegate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext

object NewsCache : IMMKVDelegate() {

    override fun mmkvName(): String = "newsCache"

    private var newsType1 by kvDelegate("")
    private var newsType2 by kvDelegate("")
    private var newsType3 by kvDelegate("")
    private var newsType4 by kvDelegate("")

    private val gson by lazy { Gson() }
    private val listType = object : TypeToken<List<ApiNewsItem>>() {}.type

    private fun kvForType(type: Int): String = when (type) {
        1 -> newsType1
        2 -> newsType2
        3 -> newsType3
        4 -> newsType4
        else -> ""
    }

    private fun saveForType(type: Int, json: String) {
        when (type) {
            1 -> newsType1 = json
            2 -> newsType2 = json
            3 -> newsType3 = json
            4 -> newsType4 = json
        }
    }

    fun getNews(type: Int): List<ApiNewsItem> {
        val json = kvForType(type)
        if (json.isEmpty()) return emptyList()
        return runCatching { gson.fromJson<List<ApiNewsItem>>(json, listType) }.getOrNull().orEmpty()
    }

    suspend fun fetchAndCacheAll() = withContext(Dispatchers.IO) {
        val types = listOf(1, 2, 3, 4)
        types.map { type ->
            async {
                runCatching {
                    val response = Remote.callApi { getGuoneinews(page = 1, size = 20, type = type) }
                    val list = response.data?.list.orEmpty()
                    if (list.isNotEmpty()) {
                        saveForType(type, gson.toJson(list))
                    }
                }
            }
        }.awaitAll()
    }
}
