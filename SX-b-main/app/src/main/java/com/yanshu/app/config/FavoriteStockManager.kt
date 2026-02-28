package com.yanshu.app.config

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import ex.ss.lib.components.mmkv.IMMKVDelegate
import ex.ss.lib.components.mmkv.kvDelegate

object FavoriteStockManager : IMMKVDelegate() {

    override fun mmkvName(): String = "stockFavorites"

    private var favoritesJson by kvDelegate("[]")
    private val gson by lazy { Gson() }
    private val typeToken = object : TypeToken<MutableSet<String>>() {}.type

    fun isFavorite(code: String, isIndex: Boolean): Boolean {
        if (code.isBlank()) return false
        return loadSet().contains(key(code, isIndex))
    }

    fun toggleFavorite(code: String, isIndex: Boolean): Boolean {
        if (code.isBlank()) return false
        val key = key(code, isIndex)
        val current = loadSet()
        val nowFavorite = if (current.contains(key)) {
            current.remove(key)
            false
        } else {
            current.add(key)
            true
        }
        saveSet(current)
        return nowFavorite
    }

    private fun key(code: String, isIndex: Boolean): String {
        return if (isIndex) "index:$code" else "stock:$code"
    }

    private fun loadSet(): MutableSet<String> {
        return runCatching {
            gson.fromJson<MutableSet<String>>(favoritesJson, typeToken)
        }.getOrNull() ?: mutableSetOf()
    }

    private fun saveSet(set: Set<String>) {
        favoritesJson = gson.toJson(set)
    }
}

