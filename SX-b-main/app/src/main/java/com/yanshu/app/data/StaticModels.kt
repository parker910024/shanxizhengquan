package com.yanshu.app.data

import java.io.Serializable

/**
 * 线路（原生项目）：后端 API base URL，例如 "https://api1.example.com"。
 * 按优先顺序排列，第一条可用的线路作为当前 API 域名。
 */
data class ApiLine(
    val name: String,
    val url: String
)

data class StaticNode(
    val name: String,
    val url: String
) : Serializable
