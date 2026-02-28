package com.yanshu.app.repo.eastmoney

object JsonpParser {

    fun unwrap(raw: String): String {
        val source = raw.trim().removePrefix("\uFEFF")
        if (source.isEmpty()) return source

        if (source.startsWith("{") || source.startsWith("[")) {
            return source
        }

        val firstParenthesis = source.indexOf('(')
        val lastParenthesis = source.lastIndexOf(')')
        if (firstParenthesis >= 0 && lastParenthesis > firstParenthesis) {
            return source.substring(firstParenthesis + 1, lastParenthesis).trim()
        }

        return source.removeSuffix(";")
    }
}

