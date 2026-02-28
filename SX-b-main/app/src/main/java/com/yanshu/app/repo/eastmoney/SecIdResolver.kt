package com.yanshu.app.repo.eastmoney

import com.yanshu.app.ui.hq.detail.model.ResolvedDetailTarget

object SecIdResolver {

    private val shIndexCodeSet = setOf("000001", "000016", "000300", "000905", "000852", "000688")

    fun resolve(code: String, marketHint: String?, isIndex: Boolean): ResolvedDetailTarget {
        val normalizedCode = normalizeCode(code)
        val hint = marketHint.orEmpty()
        val lowerHint = hint.lowercase()

        val isBeiJingStock = normalizedCode.isBeiJingCode()
        val isShHint = hint.contains('\u6Caa') || lowerHint.contains("sh")
        val isSzHint = hint.contains('\u6DF1') || hint.contains("\u521B\u4E1A") || lowerHint.contains("sz")
        val isBjHint = hint.contains('\u5317') || lowerHint.contains("bj")

        val shMarket = when {
            isIndex -> {
                when {
                    isShHint -> true
                    isSzHint || isBjHint -> false
                    normalizedCode in shIndexCodeSet -> true
                    normalizedCode.startsWith("399") -> false
                    normalizedCode.startsWith("899") -> false
                    normalizedCode.startsWith("000") -> true
                    else -> false
                }
            }

            else -> {
                when {
                    isBeiJingStock || isBjHint -> false
                    isShHint -> true
                    normalizedCode.startsWith("6") -> true
                    normalizedCode.startsWith("5") -> true
                    normalizedCode.startsWith("9") -> true
                    else -> false
                }
            }
        }

        val secId = "${if (shMarket) 1 else 0}.$normalizedCode"
        val quotePrefix = when {
            isBeiJingStock || isBjHint -> "bj"
            shMarket -> "sh"
            else -> "sz"
        }
        val quoteCode = "$quotePrefix$normalizedCode"
        val articleCode = when {
            isIndex && shMarket -> "zssh$normalizedCode"
            isIndex -> "zssz$normalizedCode"
            quotePrefix == "bj" -> normalizedCode
            else -> quoteCode
        }

        return ResolvedDetailTarget(
            rawCode = code,
            code = normalizedCode,
            secId = secId,
            quoteCode = quoteCode,
            articleCode = articleCode,
            isIndex = isIndex,
        )
    }

    private fun normalizeCode(code: String): String {
        val trimmed = code.trim()
        if (trimmed.isEmpty()) return ""

        val noSecIdPrefix = when {
            trimmed.contains(".") && trimmed.split(".").size == 2 -> trimmed.substringAfter(".")
            else -> trimmed
        }

        val noMarketPrefix = noSecIdPrefix
            .removePrefix("zssh")
            .removePrefix("zssz")
            .removePrefix("SH")
            .removePrefix("SZ")
            .removePrefix("BJ")
            .removePrefix("sh")
            .removePrefix("sz")
            .removePrefix("bj")

        val digits = noMarketPrefix.filter { it.isDigit() }
        if (digits.length <= 6) return digits
        return digits.takeLast(6)
    }

    private fun String.isBeiJingCode(): Boolean {
        return startsWith("4")
            || startsWith("8")
            || startsWith("92")
            || startsWith("83")
            || startsWith("87")
            || startsWith("43")
    }
}
