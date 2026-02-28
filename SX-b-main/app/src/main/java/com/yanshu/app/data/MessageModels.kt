package com.yanshu.app.data

/**
 * 消息列表请求（与 SX 一致：POST + Body，加密网关按 POST 识别）
 */
data class MessageListRequest(val page: Int)

/**
 * 消息列表接口返回的 data 结构
 */
data class MessageListData(
    val list: MessagePageData
)

/**
 * 消息分页数据（与文档一致）
 */
data class MessagePageData(
    val current_page: Int,
    val data: List<MessageListItem>,
    val last_page: Int,
    val per_page: Int,
    val total: Int
)

/**
 * 消息列表项（与文档一致，支持 copy 做本地已读更新）
 */
data class MessageListItem(
    val id: Int,
    val title: String,
    val createtime: String,
    val is_read: String  // "0" 未读 "1" 已读
)

/**
 * 消息详情接口返回的 data 结构
 */
data class MessageDetailData(
    val detail: String  // HTML 消息内容
)
