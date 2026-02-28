package com.yanshu.app.config

/**
 * 全局应用状态管理器
 * 用于跨 Activity 共享节点等状态信息
 */
object AppStateManager {

    /**
     * 记录节点是否全部失败或为空
     * true: 节点为空或全部连接失败
     * false: 至少有一个节点成功连接
     */
    @Volatile
    var allNodesFailedOrEmpty: Boolean = false
        private set

    /**
     * 设置节点失败状态
     * @param failed true 表示所有节点失败或为空
     */
    fun setNodesFailedOrEmpty(failed: Boolean) {
        allNodesFailedOrEmpty = failed
    }

    /**
     * 重置状态（可在重新启动或测试时调用）
     */
    fun reset() {
        allNodesFailedOrEmpty = false
    }
}

