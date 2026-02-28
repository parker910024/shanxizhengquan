package ex.ss.lib.net

import com.google.gson.Gson

/**
 * 预解析当前请求
 * 可以处理不同结果状态下的Json格式不一样的问题
 * @param gson json解析
 * @param json 当前请求返回的json数据
 * @return Pair<Boolean, String>
 *     Boolean:表示预解析的结果，如果结果为true，内部会使用原Json去解析，
 *     如果为false，会使用第二个参数的返回值去解析当前的数据。
 *
 *     注：第二个参数必须返回json格式的字符串
 */
typealias OnResponsePreCheck = (gson: Gson, json: String) -> Pair<Boolean, String>
/**
 * 公共请求头
 */
typealias OnCommonHeaderCallback = () -> MutableMap<String, String>
/**
 * 日志回调
 */
typealias OnHttpLogger = (log: String) -> Unit