package com.yanshu.app.data

/**
 * 首页新闻列表接口返回（/api/Indexnew/getGuoneinews）
 */
data class NewsListData(
    val list: List<ApiNewsItem>? = null,
    val page: Int? = null,
)

/**
 * 新闻列表项（与接口字段一致）
 */
data class ApiNewsItem(
    val news_id: String = "",
    val news_title: String = "",
    val news_abstract: String = "",
    val news_content: String = "",
    val news_image: String = "",
    val news_time: String = "",
    val news_time_text: String = "",
    val id: Int = 0,
    val type: Int = 0,
    val mode: Int = 0,
)

/**
 * 新闻详情接口返回（/api/Indexnew/getNewsssDetail）
 */
data class NewsDetailData(
    val news_id: String = "",
    val news_title: String = "",
    val news_content: String = "",
    val news_abstract: String = "",
    val news_time: String = "",
    val news_image: String = "",
    val id: Int = 0,
    val type: Int = 0,
    val mode: Int = 0,
)

/**
 * 首页轮播图接口返回（/api/index/banner）
 */
data class BannerListData(
    val list: List<BannerItem>? = null,
)

/**
 * 轮播图单项（与接口字段一致）
 */
data class BannerItem(
    val id: Int = 0,
    val title: String = "",
    val image: String = "",
    val link: String = "",
    val createtime: Long = 0L,
    val updatetime: Long = 0L,
)
