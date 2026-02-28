package com.yanshu.app.singbox

import com.yanshu.app.config.StaticConfigManager
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLDecoder

object VlessToSingboxConverter {

    const val HTTP_PORT = 10809
    const val SOCKS_PORT = 10880

    fun convert(vlessUrl: String, proxyRules: StaticConfigManager.ProxyRules? = null): String {
        val node = parseVlessUrl(vlessUrl)
        return generateConfig(node, proxyRules)
    }

    private fun parseVlessUrl(url: String): VlessNode {
        val withoutScheme = url.removePrefix("vless://")

        val nameIndex = withoutScheme.lastIndexOf("#")
        val name = if (nameIndex > 0) {
            try { URLDecoder.decode(withoutScheme.substring(nameIndex + 1), "UTF-8") }
            catch (_: Exception) { withoutScheme.substring(nameIndex + 1) }
        } else "Node"

        val urlWithoutName = if (nameIndex > 0) withoutScheme.substring(0, nameIndex) else withoutScheme
        val paramsIndex = urlWithoutName.indexOf("?")
        val params = if (paramsIndex > 0) urlWithoutName.substring(paramsIndex + 1) else ""
        val urlWithoutParams = if (paramsIndex > 0) urlWithoutName.substring(0, paramsIndex) else urlWithoutName

        val atIndex = urlWithoutParams.indexOf("@")
        val uuid = if (atIndex > 0) urlWithoutParams.substring(0, atIndex) else ""
        val serverPort = if (atIndex > 0) urlWithoutParams.substring(atIndex + 1) else urlWithoutParams

        val colonIndex = serverPort.lastIndexOf(":")
        val server = if (colonIndex > 0) serverPort.substring(0, colonIndex) else serverPort
        val port = if (colonIndex > 0) serverPort.substring(colonIndex + 1).toIntOrNull() ?: 443 else 443

        val paramMap = mutableMapOf<String, String>()
        if (params.isNotEmpty()) {
            params.split("&").forEach { p ->
                val kv = p.split("=", limit = 2)
                if (kv.size == 2) {
                    paramMap[kv[0]] = try { URLDecoder.decode(kv[1], "UTF-8") } catch (_: Exception) { kv[1] }
                }
            }
        }

        return VlessNode(name, uuid, server, port,
            paramMap["type"] ?: "tcp",
            paramMap["security"] ?: "none",
            paramMap["sni"] ?: "",
            paramMap["host"] ?: "",
            paramMap["path"] ?: "",
            paramMap["flow"] ?: "",
            paramMap["pbk"] ?: "",
            paramMap["sid"] ?: "",
            paramMap["fp"] ?: "chrome"
        )
    }

    private fun generateConfig(node: VlessNode, proxyRules: StaticConfigManager.ProxyRules? = null): String {
        return JSONObject().apply {
            put("log", JSONObject().apply {
                put("level", "info")
                put("timestamp", true)
            })

            put("inbounds", JSONArray().apply {
                put(JSONObject().apply {
                    put("type", "http")
                    put("tag", "http-in")
                    put("listen", "127.0.0.1")
                    put("listen_port", HTTP_PORT)
                })
                put(JSONObject().apply {
                    put("type", "socks")
                    put("tag", "socks-in")
                    put("listen", "127.0.0.1")
                    put("listen_port", SOCKS_PORT)
                })
            })

            put("outbounds", JSONArray().apply {
                put(createVlessOutbound(node))
            })
        }.toString(2)
    }

    private fun createVlessOutbound(node: VlessNode): JSONObject {
        return JSONObject().apply {
            put("type", "vless")
            put("tag", "proxy")
            put("server", node.server)
            put("server_port", node.port)
            put("uuid", node.uuid)

            if (node.flow.isNotEmpty()) put("flow", node.flow)

            when (node.security) {
                "tls" -> put("tls", JSONObject().apply {
                    put("enabled", true)
                    put("server_name", node.sni.ifEmpty { node.host.ifEmpty { node.server } })
                    put("insecure", true)
                    if (node.fp.isNotEmpty()) {
                        put("utls", JSONObject().apply {
                            put("enabled", true)
                            put("fingerprint", node.fp)
                        })
                    }
                })
                "reality" -> put("tls", JSONObject().apply {
                    put("enabled", true)
                    put("server_name", node.sni.ifEmpty { node.host })
                    put("utls", JSONObject().apply {
                        put("enabled", true)
                        put("fingerprint", node.fp.ifEmpty { "chrome" })
                    })
                    put("reality", JSONObject().apply {
                        put("enabled", true)
                        put("public_key", node.pbk)
                        put("short_id", node.sid)
                    })
                })
            }

            when (node.network) {
                "ws" -> put("transport", JSONObject().apply {
                    put("type", "ws")
                    put("path", node.path.ifEmpty { "/" })
                    if (node.host.isNotEmpty()) {
                        put("headers", JSONObject().put("Host", node.host))
                    }
                })
                "grpc" -> put("transport", JSONObject().apply {
                    put("type", "grpc")
                    put("service_name", node.path)
                })
                "h2", "http" -> put("transport", JSONObject().apply {
                    put("type", "http")
                    if (node.host.isNotEmpty()) put("host", JSONArray().put(node.host))
                    put("path", node.path.ifEmpty { "/" })
                })
            }
        }
    }

    data class VlessNode(
        val name: String, val uuid: String, val server: String, val port: Int,
        val network: String, val security: String, val sni: String,
        val host: String, val path: String, val flow: String,
        val pbk: String, val sid: String, val fp: String
    )
}
